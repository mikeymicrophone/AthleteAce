require "rails_helper"

RSpec.describe DecisionModels::Client do
  let(:choices) { DecisionModels::Policies::CONTENT_CHOICES }
  let(:http) { double("HTTP transport") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    %w[TYPESAFE_API_KEY OPENAI_API_KEY].each do |key|
      allow(ENV).to receive(:[]).with(key).and_return("fixture-key")
      allow(ENV).to receive(:fetch).with(key).and_return("fixture-key")
    end
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  def response(provider, **changes)
    answer = { "type" => "choice", "choice" => "allow", "confidence" => 0.8,
      "probabilities" => { "allow" => 0.9, "review" => 0.08, "block" => 0.02 } }.merge(changes.stringify_keys)
    if provider == "openai"
      answer["name"] = "route"
      answer["probabilities"] = answer["probabilities"].map { |key, value| { "value" => key, "probability" => value } }
    end
    { "model" => provider == "jev" ? "jev-1.13.0" : "gpt-6-luna",
      "answers" => provider == "jev" ? { "route" => answer } : [ answer ], "usage" => { "input_tokens" => 2000 } }
  end

  def transport(body, status: "200")
    reply = status == "200" ? Net::HTTPOK.new("1.1", status, "OK") : Net::HTTPTooManyRequests.new("1.1", status, "Rate limited")
    allow(reply).to receive(:body).and_return(body.is_a?(String) ? body : JSON.generate(body))
    allow(http).to receive(:request).and_return(reply)
    reply
  end

  def call(provider)
    described_class.new(provider).call(state: { text: "Ordinary sports discussion" }, instructions: "Classify the content", choices: choices)
  end

  %w[jev openai].each do |provider|
    it "uses the documented #{provider} request and records validated typed answers and usage" do
      reply = transport(response(provider))
      expect(http).to receive(:request) do |request|
        payload = JSON.parse(request.body)
        expect(request["Authorization"]).to eq("Bearer fixture-key")
        if provider == "jev"
          expect(request.path).to eq("/v1/systemone")
          expect(payload.fetch("questions").fetch("route").fetch("criteria")).to eq(choices)
        else
          expect(request.path).to eq("/v1/decisions")
          expect(payload.fetch("questions").first.fetch("choices").map { |item| item.fetch("value") }).to eq(choices.keys)
        end
        reply
      end
      result = call(provider)
      expect(result.answer.fetch("choice")).to eq("allow")
      expect(result.input_tokens).to eq(2000)
    end

    it "rejects unknown choices and invalid probabilities from #{provider}" do
      transport(response(provider, choice: "publish_everything"))
      expect { call(provider) }.to raise_error(described_class::Error, "invalid_answer")
      transport(response(provider, confidence: 1.1))
      expect { call(provider) }.to raise_error(described_class::Error, "invalid_probabilities")
      transport(response(provider, probabilities: { "allow" => 0.8, "review" => 0.1, "block" => -0.1 }))
      expect { call(provider) }.to raise_error(described_class::Error, "invalid_probabilities")
    end
  end

  it "keeps missing usage unknown and handles refusals, invalid usage, transport errors, and malformed JSON" do
    data = response("openai")
    data.delete("usage")
    transport(data)
    expect(call("openai").input_tokens).to be_nil
    transport(response("openai", type: "refusal"))
    expect { call("openai") }.to raise_error(described_class::Error, "refused")
    data = response("openai")
    data["usage"]["input_tokens"] = -1
    transport(data)
    expect { call("openai") }.to raise_error(described_class::Error, "invalid_usage")
    transport("Not JSON")
    expect { call("openai") }.to raise_error(described_class::Error, "invalid_response")
    transport("Secret server error", status: "429")
    expect { call("openai") }.to raise_error(described_class::Error, "http_429")
    allow(http).to receive(:request).and_raise(Net::ReadTimeout)
    expect { call("openai") }.to raise_error(described_class::Error, "timeout")
  end
end

RSpec.describe DecisionModels::Compare do
  let(:record) { create(:quest, created_by: create(:ace)) }
  let(:task) { DecisionModels::Policies.content(state: record.moderation_snapshot) }
  let(:answer) { { "type" => "choice", "choice" => "allow", "confidence" => 0.8 } }

  before do
    allow_any_instance_of(DecisionModels::Client).to receive(:configured?).and_return(true)
    allow_any_instance_of(DecisionModels::Client).to receive(:call).and_return(
      DecisionModels::Client::Result.new(model: "fixture-model", answer: answer, input_tokens: 2000))
  end

  it "records separate costs and recommendations, repeats idempotently, and never publishes" do
    rows = described_class.call(task: task, subject: record, comparison_key: "comparison-one")
    expect(record.reload.moderation_status).to eq("pending")
    expect(rows.map(&:estimated_usd)).to eq([ BigDecimal("0.000084"), BigDecimal("0.0002") ])
    expect(rows.map(&:revision)).to eq([ 1, 1 ])
    expect(rows.map(&:choice)).to eq(%w[allow allow])
    expect {
      described_class.call(task: task, subject: record, comparison_key: "comparison-one")
    }.not_to change(DecisionEvaluation, :count)
    record.update!(name: "Changed")
    expect {
      described_class.call(task: DecisionModels::Policies.content(state: record.moderation_snapshot), subject: record, comparison_key: "comparison-one")
    }.to raise_error(ArgumentError, /different content/)
  end

  it "records unavailable keys and failures without inventing zero cost" do
    allow_any_instance_of(DecisionModels::Client).to receive(:configured?).and_return(false)
    rows = described_class.call(task: task, subject: record, comparison_key: "unavailable")
    expect(rows.map(&:status)).to eq(%w[unavailable unavailable])
    expect(rows.map(&:estimated_usd)).to eq([ nil, nil ])
    allow_any_instance_of(DecisionModels::Client).to receive(:configured?).and_return(true)
    allow_any_instance_of(DecisionModels::Client).to receive(:call).and_raise(DecisionModels::Client::Error, "timeout")
    rows = described_class.call(task: task, subject: record, comparison_key: "timeout")
    expect(rows.map(&:status)).to eq(%w[failed failed])
    expect(record.reload.moderation_status).to eq("pending")
  end
end
