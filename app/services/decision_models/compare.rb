module DecisionModels
  class Compare
    def self.call(task:, comparison_key:, subject: nil)
      revision = subject&.moderation_revision
      Client::CONFIG.keys.map do |provider|
        client = Client.new(provider)
        evaluation = DecisionEvaluation.create_or_find_by!(comparison_key: comparison_key, provider: provider) do |row|
          row.assign_attributes(subject: subject, revision: revision,
            model: client.config.fetch(:model), purpose: task.fetch(:purpose), policy_version: task.fetch(:policy_version),
            request_snapshot: task, input_usd_per_million: client.config.fetch(:rate))
        end
        unless evaluation.subject == subject && evaluation.request_snapshot == task.deep_stringify_keys
          raise ArgumentError, "This comparison key belongs to different content. Start a new comparison."
        end
        run(evaluation, client)
        evaluation.reload
      end
    end

    def self.run(evaluation, client)
      claimed = evaluation.with_lock do
        next false unless evaluation.status == "queued"
        evaluation.update!(status: client.configured? ? "running" : "unavailable", error_code: client.configured? ? nil : "missing_key")
        evaluation.status == "running"
      end
      return unless claimed

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      request = evaluation.request_snapshot.symbolize_keys
      result = client.call(**request.slice(:state, :instructions, :choices))
      cost = result.input_tokens && evaluation.input_usd_per_million * result.input_tokens / 1_000_000
      evaluation.update!(status: "completed", model: result.model, answer: result.answer,
        choice: result.answer.fetch("choice"), input_tokens: result.input_tokens, estimated_usd: cost,
        latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round)
    rescue Client::Error => error
      evaluation.update!(status: "failed", error_code: error.message,
        latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round)
    end
    private_class_method :run
  end
end
