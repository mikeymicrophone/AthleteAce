require "net/http"

module DecisionModels
  class Client
    class Error < StandardError; end
    CONFIG = {
      "jev" => { endpoint: "https://api.typesafe.ai/v1/systemone", model: "jev-1.13.0", key: "TYPESAFE_API_KEY", rate: "0.042" },
      "openai" => { endpoint: "https://api.openai.com/v1/decisions", model: "gpt-6-luna", key: "OPENAI_API_KEY", rate: "0.10" }
    }.freeze
    Result = Data.define(:model, :answer, :input_tokens)

    attr_reader :provider, :config

    def initialize(provider)
      @provider = provider.to_s
      @config = CONFIG.fetch(@provider)
    end

    def configured?
      ENV[config.fetch(:key)].present?
    end

    def call(state:, instructions:, choices:)
      raise Error, "missing_key" unless configured?
      input = JSON.generate(state)
      raise Error, "input_too_large" if input.length > 12_000
      question = { type: "choice", instructions: instructions }
      payload = if provider == "jev"
        { model: config.fetch(:model), state: input, questions: { route: question.merge(criteria: choices) } }
      else
        { model: config.fetch(:model), input: input,
          questions: [ question.merge(name: "route", choices: choices.map { |value, description| { value: value, description: description } }) ] }
      end
      uri = URI(config.fetch(:endpoint))
      request = Net::HTTP::Post.new(uri, "Authorization" => "Bearer #{ENV.fetch(config.fetch(:key))}", "Content-Type" => "application/json")
      request.body = JSON.generate(payload)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10, write_timeout: 10) { |http| http.request(request) }
      raise Error, "http_#{response.code}" unless response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      answer = if provider == "jev"
        data.fetch("answers").fetch("route")
      else
        answers = data.fetch("answers").select { |entry| entry["name"] == "route" }
        raise Error, "invalid_answer" unless answers.one?
        answers.first
      end
      raise Error, "refused" if answer["type"] == "refusal"
      validate_answer!(answer, choices.keys)
      tokens = data.dig("usage", "input_tokens")
      raise Error, "invalid_usage" unless tokens.nil? || (tokens.is_a?(Integer) && tokens >= 0)
      Result.new(model: data["model"].presence || config.fetch(:model), answer: answer, input_tokens: tokens)
    rescue JSON::ParserError, KeyError, TypeError, NoMethodError
      raise Error, "invalid_response"
    rescue Timeout::Error
      raise Error, "timeout"
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError, IOError
      raise Error, "connection_failed"
    end

    private

    def validate_answer!(answer, choices)
      raise Error, "invalid_answer" unless answer["type"] == "choice" && choices.include?(answer["choice"])
      probabilities = if provider == "jev"
        answer.fetch("probabilities")
      else
        entries = answer.fetch("probabilities")
        raise Error, "invalid_probabilities" unless entries.size == entries.map { |entry| entry["value"] }.uniq.size
        entries.to_h { |entry| [ entry.fetch("value"), entry.fetch("probability") ] }
      end
      valid = ->(value) { value.is_a?(Numeric) && value.finite? && value.between?(0, 1) }
      unless probabilities.is_a?(Hash) && probabilities.keys.sort == choices.sort && probabilities.values.all?(&valid) &&
          (probabilities.values.sum - 1).abs <= 0.02 && valid.call(answer["confidence"])
        raise Error, "invalid_probabilities"
      end
    end
  end
end
