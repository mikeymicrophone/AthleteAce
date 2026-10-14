require "rails_helper"
require "rake"

RSpec.describe "decisions:compare" do
  it "reports unknown totals and exits nonzero when providers are unavailable" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("decisions:compare")
    task = Rake::Task["decisions:compare"]
    task.reenable
    allow_any_instance_of(DecisionModels::Client).to receive(:configured?).and_return(false)
    previous_stdout = $stdout
    $stdout = StringIO.new
    expect { task.invoke }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    lines = $stdout.string.lines.map { |line| JSON.parse(line) }
    summary = lines.last.fetch("smoke_comparison")
    expect(summary.keys).to match_array(%w[jev openai])
    summary.each_value do |row|
      expect(row.fetch("completed")).to eq(0)
      expect(row.fetch("unavailable")).to eq(8)
      expect(row.fetch("unknown_cost")).to eq(8)
      expect(row.fetch("estimated_usd")).to be_nil
    end
    expect(lines.size).to eq(17)
  ensure
    $stdout = previous_stdout
  end
end
