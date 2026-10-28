class PracticeReview < ApplicationRecord
  INTERVALS = [ 1.day, 3.days, 7.days, 14.days, 30.days ].freeze

  belongs_to :ace
  belongs_to :last_attempt, class_name: "GameAttempt"
  scope :due, ->(now = Time.current) { where(due_at: ..now).order(:due_at, :id) }

  def self.record!(attempt, question)
    question = question.dup
    question["team_id"] ||= attempt.target_entity_id if attempt.target_entity_type == "Team"
    question["team_id"] ||= attempt.subject_entity_id if attempt.subject_entity_type == "Team"
    mode = question.fetch("game_type", attempt.game_type)
    key = { ace: attempt.ace, game_type: mode, subject_type: attempt.subject_entity_type,
      subject_id: attempt.subject_entity_id, target_type: attempt.target_entity_type, target_id: attempt.target_entity_id }
    review = create_or_find_by!(key) do |record|
      record.question = question.merge("game_type" => mode)
      record.last_attempt = attempt
      record.correct_streak = attempt.correct? ? 1 : 0
      record.due_at = attempt.created_at + (attempt.correct? ? INTERVALS.first : 10.minutes)
    end
    review.with_lock do
      next if review.last_attempt_id >= attempt.id

      streak = attempt.correct? ? review.correct_streak + 1 : 0
      review.update! question: question.merge("game_type" => mode), last_attempt: attempt, correct_streak: streak,
        due_at: attempt.created_at + (attempt.correct? ? INTERVALS.fetch([ streak - 1, INTERVALS.size - 1 ].min) : 10.minutes)
    end
  end
end
