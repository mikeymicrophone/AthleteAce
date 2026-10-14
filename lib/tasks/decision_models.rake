namespace :decisions do
  desc "Compare Jev and OpenAI Luna on the bundled smoke cases without changing content"
  task compare: :environment do
    cases = JSON.parse(Rails.root.join("spec/fixtures/decision_cases.json").read)
    raise "The comparison has no cases." if cases.empty?
    results = cases.flat_map do |example|
      task = case example.fetch("purpose")
      when "sports_data"
        DecisionModels::Policies.sports_data(state: example.fetch("state"), candidates: example.fetch("candidates"))
      when "content_policy"
        DecisionModels::Policies.content(state: example.fetch("state"))
      else
        raise "Unknown comparison purpose"
      end
      DecisionModels::Compare.call(task: task, comparison_key: SecureRandom.uuid).map do |row|
        result = { case: example.fetch("id"), provider: row.provider, status: row.status,
          expected: example.fetch("expected"), choice: row.choice, input_tokens: row.input_tokens,
          estimated_usd: row.estimated_usd&.to_s("F"), latency_ms: row.latency_ms, error: row.error_code }
        puts result.to_json
        result
      end
    end
    summary = results.group_by { |row| row[:provider] }.transform_values do |rows|
      completed = rows.select { |row| row[:status] == "completed" }
      { completed: completed.size, failed: rows.count { |row| row[:status] == "failed" },
        unavailable: rows.count { |row| row[:status] == "unavailable" },
        correct: completed.count { |row| row[:choice] == row[:expected] },
        unknown_cost: rows.count { |row| row[:estimated_usd].nil? },
        estimated_usd: rows.all? { |row| row[:estimated_usd] } ? rows.sum(0.to_d) { |row| row[:estimated_usd].to_d }.to_s("F") : nil }
    end
    puts({ smoke_comparison: summary }.to_json)
    abort "Comparison incomplete. Inspect failed or unavailable rows." unless results.all? { |row| row[:status] == "completed" }
    abort "Comparison differs from smoke labels. Inspect the results." unless results.all? { |row| row[:choice] == row[:expected] }
  end
end
