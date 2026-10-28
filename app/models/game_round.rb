class GameRound < ApplicationRecord
  class InvalidAction < StandardError; end

  GAMES = { "player_team_match" => "Team Match", "guess_the_division" => "Guess the Division", "name_ciphers" => "Name Ciphers",
    "multiple_choice" => "Multiple Choice", "phased_repetition" => "Phased Repetition", "image_recognition" => "Image Recognition" }.freeze
  LENGTHS = [ 10, 20, 30 ].freeze

  belongs_to :ace
  has_many :game_attempts, dependent: :destroy
  scope :unfinished, -> { where(finished_at: nil).order(updated_at: :desc) }

  validates :game_type, inclusion: { in: GAMES.keys }
  validates :length, numericality: { only_integer: true, in: 1..30 }
  validates :scope_label, :started_at, presence: true
  validate { errors.add(:questions, "must match the round length") unless questions.size == length }
  before_create :record_starting_quest_progress

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

  def repeats_subjects?
    questions.map { |item| [ item.fetch("subject_type"), item.fetch("subject_id") ] }.uniq.size < questions.size
  end

  def miss_count_for(attempt)
    return 0 unless attempt && attempt.game_round_id == id && !attempt.correct?

    history = ace.game_attempts.where(game_type: game_type, subject_entity_type: attempt.subject_entity_type,
      subject_entity_id: attempt.subject_entity_id, target_entity_type: attempt.target_entity_type,
      target_entity_id: attempt.target_entity_id, id: ..attempt.id)
    last_correct = history.where(is_correct: true).maximum(:id) || 0
    history.where(is_correct: false).where("id > ?", last_correct).count
  end

  # Lock the round and identify the question, so retries and stale tabs cannot
  # record twice or accidentally answer the following question.
  def answer!(at:, choice_id:)
    with_lock do
      raise InvalidAction, "This question has already moved on." unless at.to_s == position.to_s && !completed?
      return current_attempt if current_attempt
      raise InvalidAction, "Resume the round before answering." if paused?

      choice = question.fetch("choices").find { |item| item.fetch("id").to_s == choice_id.to_s }
      raise InvalidAction, "Choose one of the answers shown." if choice_id.present? && !choice

      known_before = PlayProgress.new(ace: ace).known_player_ids.include?(question.fetch("subject_id")) if question.fetch("subject_type") == "Player"
      attempt = game_attempts.create! ace: ace, game_type: game_type, round_position: position,
        subject_entity_type: question.fetch("subject_type"), subject_entity_id: question.fetch("subject_id"),
        target_entity_type: question.fetch("target_type"), target_entity_id: question.fetch("target_id"),
        chosen_entity_type: choice && question.fetch("target_type"), chosen_entity_id: choice&.fetch("id"),
        options_presented: question.fetch("choices").map { |item| item.fetch("id") },
        is_correct: choice&.fetch("id") == question.fetch("target_id"), time_elapsed_ms: answer_time_ms
      PracticeReview.record! attempt, question
      ace.goals.active.where(quest: Quest.approved).find_each { |goal| goal.record_answer!(attempt) }
      learned = newly_known_player_ids
      if known_before == false && attempt.correct? && PlayProgress.new(ace: ace).known_player_ids.include?(attempt.subject_entity_id)
        learned |= [ attempt.subject_entity_id ]
      end
      update! question_started_at: nil, question_elapsed_ms: 0, newly_known_player_ids: learned
      attempt
    end
  end

  def advance!(at:)
    with_lock do
      return if completed? || at.to_s != position.to_s
      raise InvalidAction, "Answer this question before continuing." unless current_attempt
      raise InvalidAction, "Resume the round before continuing." if paused?

      next_position = position + 1
      completed_at = next_position == length ? Time.current : nil
      changes = { position: next_position, finished_at: completed_at,
        question_started_at: completed_at ? nil : Time.current }
      if completed_at && scope["quest_progress"]
        entries = quest_learning_entries(as_of: completed_at).index_by(&:goal_id)
        snapshots = scope.fetch("quest_progress").map do |snapshot|
          entry = entries[snapshot.fetch("goal_id")]
          entry ? snapshot.merge("after" => quest_progress_snapshot(entry.goal)) : snapshot
        end
        changes[:scope] = scope.merge("quest_progress" => snapshots)
      end
      update! changes
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

  def quest_learning_entries(as_of: finished_at || Time.current)
    player_ids = questions.filter_map { |question| question["subject_id"] if question["subject_type"] == "Player" }.uniq
    return [] if player_ids.empty?

    entries = GoalAchievement.joins(:achievement, goal: { quest: :highlights })
      .merge(Quest.approved).merge(Achievement.approved).merge(Highlight.approved)
      .where(goals: { ace_id: ace_id }).where("goals.created_at <= ?", as_of)
      .where("highlights.achievement_id = goal_achievements.achievement_id")
      .where("EXISTS (SELECT 1 FROM jsonb_array_elements_text(goal_achievements.required_player_ids) AS member(value) WHERE member.value IN (?))", player_ids.map(&:to_s))
    if scope["goal_achievement_id"]
      entries = entries.where(id: scope["goal_achievement_id"], achievements: { target_type: "PlayerGroup", target_id: scope["player_group_id"] })
    else
      entries = entries.where.not(achievements: { target_type: "PlayerGroup" })
    end
    entries.includes(:achievement, goal: :quest).order(:goal_id, :id).group_by(&:goal_id).values.map do |matches|
      matches.find { |entry| !entry.completed_at } || matches.first
    end
  end

  def stats
    streak = best = 0
    attempts = results
    attempts.each do |attempt|
      streak = attempt.correct? ? streak + 1 : 0
      best = [ best, streak ].max
    end
    { correct: attempts.count(&:correct?), answered: attempts.size, streak: streak, best_streak: best,
      elapsed_ms: attempts.sum(&:time_elapsed_ms) }
  end

  def drill_misses!
    raise InvalidAction, "Finish the round before drilling its misses." unless completed?

    missed = results.reject(&:correct?).map { |attempt| questions.fetch(attempt.round_position) }
      .uniq { |item| [ item.fetch("subject_type"), item.fetch("subject_id") ] }
    raise InvalidAction, "There are no misses to drill." if missed.empty?

    ace.game_rounds.create! game_type: game_type, length: missed.size, questions: missed,
      scope: scope.merge("drill" => true), scope_label: "Misses · #{scope_label.delete_prefix('Misses · ')}",
      started_at: Time.current, question_started_at: Time.current
  end

  private

  def record_starting_quest_progress
    self.scope = scope.except("quest_progress")
    entries = quest_learning_entries(as_of: started_at)
    return if entries.empty?

    snapshots = entries.map { |entry| { "goal_id" => entry.goal_id, "before" => quest_progress_snapshot(entry.goal) } }
    self.scope = scope.merge("quest_progress" => snapshots)
  end

  def quest_progress_snapshot(goal)
    required = goal.quest.highlights.public_requirements.required.count
    completed = [ goal.progress, required ].min
    { "completed" => completed, "required" => required,
      "percent" => required.positive? ? (completed.fdiv(required) * 100).round : 0 }
  end

  def answer_time_ms
    elapsed = question_started_at ? ((Time.current - question_started_at) * 1000).round : 0
    [ question_elapsed_ms + [ elapsed, 0 ].max, 2_147_483_647 ].min
  end
end
