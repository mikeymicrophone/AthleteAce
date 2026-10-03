class GameRound < ApplicationRecord
  class InvalidAction < StandardError; end

  GAMES = { "player_team_match" => "Team Match", "guess_the_division" => "Guess the Division" }.freeze
  LENGTHS = [10, 20, 30].freeze

  belongs_to :ace
  has_many :game_attempts, dependent: :destroy
  scope :unfinished, -> { where(finished_at: nil).order(updated_at: :desc) }

  validates :game_type, inclusion: { in: GAMES.keys }
  validates :length, numericality: { only_integer: true, in: 1..30 }
  validates :scope_label, :started_at, presence: true
  validate { errors.add(:questions, "must match the round length") unless questions.size == length }

  def question
    questions[position]
  end

  def current_attempt
    game_attempts.find_by round_position: position
  end

  def completed?
    finished_at.present?
  end

  def paused?
    paused_at.present?
  end

  # Lock the round and identify the question, so retries and stale tabs cannot
  # record twice or accidentally answer the following question.
  def answer! at:, choice_id:
    with_lock do
      raise InvalidAction, "This question has already moved on." unless at.to_s == position.to_s && !completed?
      return current_attempt if current_attempt
      raise InvalidAction, "Resume the round before answering." if paused?

      choice = question.fetch("choices").find { |item| item.fetch("id").to_s == choice_id.to_s }
      raise InvalidAction, "Choose one of the answers shown." if choice_id.present? && !choice

      attempt = game_attempts.create! ace: ace, game_type: game_type, round_position: position,
        subject_entity_type: question.fetch("subject_type"), subject_entity_id: question.fetch("subject_id"),
        target_entity_type: question.fetch("target_type"), target_entity_id: question.fetch("target_id"),
        chosen_entity_type: choice && question.fetch("target_type"), chosen_entity_id: choice&.fetch("id"),
        options_presented: question.fetch("choices").map { |item| item.fetch("id") },
        is_correct: choice&.fetch("id") == question.fetch("target_id"), time_elapsed_ms: answer_time_ms
      update! question_started_at: nil, question_elapsed_ms: 0
      attempt
    end
  end

  def advance! at:
    with_lock do
      return if completed? || at.to_s != position.to_s
      raise InvalidAction, "Answer this question before continuing." unless current_attempt
      raise InvalidAction, "Resume the round before continuing." if paused?

      next_position = position + 1
      update! position: next_position, finished_at: next_position == length ? Time.current : nil,
        question_started_at: next_position == length ? nil : Time.current
    end
  end

  def pause!
    with_lock do
      return if completed? || paused?

      update! paused_at: Time.current, question_elapsed_ms: answer_time_ms, question_started_at: nil
    end
  end

  def resume!
    with_lock do
      return if completed? || !paused?

      update! paused_at: nil, question_started_at: current_attempt ? nil : Time.current
    end
  end

  def results
    game_attempts.order(:round_position).to_a
  end

  def stats
    streak = best = 0
    attempts = results
    attempts.each do |attempt|
      streak = attempt.correct? ? streak + 1 : 0
      best = [best, streak].max
    end
    { correct: attempts.count(&:correct?), answered: attempts.size, streak: streak, best_streak: best,
      elapsed_ms: attempts.sum(&:time_elapsed_ms) }
  end

  def drill_misses!
    raise InvalidAction, "Finish the round before drilling its misses." unless completed?

    missed = results.reject(&:correct?).map { |attempt| questions.fetch(attempt.round_position) }
      .uniq { |item| [item.fetch("subject_type"), item.fetch("subject_id")] }
    raise InvalidAction, "There are no misses to drill." if missed.empty?

    ace.game_rounds.create! game_type: game_type, length: missed.size, questions: missed,
      scope: scope.merge("drill" => true), scope_label: "Misses · #{scope_label.delete_prefix('Misses · ')}",
      started_at: Time.current, question_started_at: Time.current
  end

  private

  def answer_time_ms
    elapsed = question_started_at ? ((Time.current - question_started_at) * 1000).round : 0
    [question_elapsed_ms + [elapsed, 0].max, 2_147_483_647].min
  end
end
