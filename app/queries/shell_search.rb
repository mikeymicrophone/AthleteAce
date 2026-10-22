class ShellSearch
  LIMIT = 5
  NAMED_MODELS = [ Sport, League, Conference, Division, Country, State, City, Stadium ].freeze

  attr_reader :query

  def initialize(query:, side:, ace:, seed: SecureRandom.hex(16))
    @query = query.to_s.strip.first(80)
    @ace = ace
    @seed = seed
    @side = case side
    when "admin" then ace&.admin? ? "admin" : "play"
    when "mod" then ace&.can_moderate? ? "mod" : "play"
    else side
    end
  end

  def groups
    return {} if query.length < 2

    if @side == "mod"
      { "Queue" => queue, "Aces" => aces }.reject { |_name, records| records.empty? }
    else
      groups = {
        "Players" => Player.where("CONCAT_WS(' ', first_name, last_name, array_to_string(nicknames, ' ')) ILIKE ?", pattern)
          .order(:last_name, :first_name, :id).limit(LIMIT).to_a,
        "Teams" => Team.matching_name(query).order(:territory, :mascot, :id).limit(LIMIT).to_a
      }
      groups["Shout-outs"] = ShoutOutFeed.ranked(ShoutOut.live.matching_text(query), seed: @seed).limit(LIMIT).to_a if @side == "feed"
      unless @side == "feed"
        NAMED_MODELS.each do |model|
          expression = [ League, Conference, Division ].include?(model) ? "CONCAT_WS(' ', name, abbreviation)" : "name"
          groups[model.model_name.human.pluralize] = model.where("#{expression} ILIKE ?", pattern).order(:name, :id).limit(LIMIT).to_a
        end
      end
      if @side == "admin"
        groups["Aces"] = aces
        groups["Organizations"] = Organization.where("name ILIKE ?", pattern).order(:name, :id).limit(LIMIT).to_a
      end
      groups.reject { |_name, records| records.empty? }
    end
  end

  private

  def pattern
    "%#{ApplicationRecord.sanitize_sql_like(query)}%"
  end

  def aces
    Ace.where("CONCAT_WS(' ', '@' || username, display_name) ILIKE ?", pattern).order(:username, :id).limit(LIMIT).to_a
  end

  def queue
    Moderation::Queue::TYPES.values.flat_map do |model|
      scope = model.where(moderation_status: "pending").where("#{model.table_name}.created_by_id IS NULL OR #{model.table_name}.created_by_id != ?", @ace.id)
      scope = scope.where(funding_status: "reserved") if model == ShoutOut
      scope = if model == Highlight
        scope.joins(:quest, :achievement).where("quests.name ILIKE :term OR achievements.name ILIKE :term", term: pattern)
      elsif model == ShoutOut
        scope.where("target_name ILIKE :term OR message ILIKE :term", term: pattern)
      else
        scope.where("#{model.table_name}.name ILIKE ?", pattern)
      end
      scope.order(:created_at, :id).limit(LIMIT).to_a
    end.sort_by { |record| [ record.created_at, record.class.name, record.id ] }.first(LIMIT)
  end
end
