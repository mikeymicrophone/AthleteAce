class Goal < ApplicationRecord
  belongs_to :ace
  belongs_to :quest
  has_many :goal_achievements, dependent: :destroy

  after_create :prepare_learning!

  def prepare_learning!
    quest.highlights.public_requirements.includes(:achievement).find_each do |highlight|
      next if goal_achievements.exists?(achievement: highlight.achievement)
      snapshot = highlight.achievement.roster_snapshot
      next unless snapshot

      goal_achievements.create_or_find_by!(achievement: highlight.achievement) do |entry|
        entry.required_player_ids = snapshot.fetch(:ids)
        entry.practice_scope = snapshot.fetch(:scope)
      end
    end
  end

  def record_answer!(attempt)
    return unless attempt.correct? && attempt.subject_entity_type == "Player" && attempt.created_at >= created_at && quest.approved?

    with_lock do
      prepare_learning!
      highlights = quest.highlights.public_requirements
      entries = goal_achievements.where(achievement_id: highlights.select(:achievement_id))
      matched = false
      entries.each do |entry|
        next unless entry.required_player_ids.include?(attempt.subject_entity_id)

        matched = true
        entry.player_ids |= [ attempt.subject_entity_id ]
        entry.completed_at ||= attempt.created_at if entry.progress == entry.required_player_ids.size
        entry.save!
      end
      if matched
        completed = entries.where.not(completed_at: nil).where(achievement_id: highlights.required.select(:achievement_id)).count
        total = highlights.required.count
        update! progress: completed, status: total.positive? && completed >= total ? "completed" : "in_progress"
      end
    end
  end

  def next_achievement
    completed = goal_achievements.where.not(completed_at: nil).select(:achievement_id)
    quest.highlights.public_requirements.required.ordered.where.not(achievement_id: completed).includes(:achievement).map(&:achievement).find { |achievement| achievement.practice_scope }
  end

  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate(on: :create) { errors.add(:quest, "must be approved") if quest && !quest.approved? }
  
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.status ||= 'not_started'
    self.progress ||= 0
  end
  
  def percent_complete
    total_required = quest.highlights.public_requirements.required.count
    return 0 if total_required.zero?
    
    (progress.to_f / total_required * 100).round
  end
  
  def required_achievements
    quest.required_achievements
  end
  
  def optional_achievements
    quest.optional_achievements
  end
  
  def all_achievements
    quest.achievements.approved.merge(Highlight.approved)
  end
  
  scope :active, -> { where.not(status: 'completed') }
end
