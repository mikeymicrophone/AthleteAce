class Ace < ApplicationRecord
  THEMES = %w[light dark system].freeze
  AVATAR_COLORS = { "Umber" => "#7A4B2A", "Harbor" => "#365A78", "Forest" => "#32634A",
    "Plum" => "#704267", "Slate" => "#485569", "Rust" => "#93452F" }.freeze
  RESERVED_USERNAMES = %w[admin administrator moderator athleteace athlete_ace support system staff help].freeze

  normalizes :username, with: ->(value) { value.strip.downcase.presence }
  normalizes :display_name, with: ->(value) { value.strip }
  validates :theme, inclusion: { in: THEMES }
  validates :username, presence: true, if: -> { new_record? || username_changed? || validation_context == :profile }
  validates :username, length: { in: 3..24 }, format: { with: /\A[a-z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" },
    uniqueness: { case_sensitive: false }, exclusion: { in: RESERVED_USERNAMES }, allow_nil: true
  validates :display_name, presence: true, length: { maximum: 60 }, if: -> { username.present? }
  validates :avatar_color, inclusion: { in: AVATAR_COLORS.values }
  validate :keep_username

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable

  has_many :goals, dependent: :destroy
  has_many :active_goals, -> { Goal.active }, class_name: "Goal"
  has_many :quests, through: :goals
  has_many :ratings, dependent: :destroy
  has_many :game_attempts, dependent: :destroy
  has_many :game_rounds, dependent: :destroy

  def can_moderate?
    admin? || moderator?
  end

  def handle
    "@#{username}" if username.present?
  end

  def public_name
    display_name.presence || handle || "Ace"
  end

  def initials
    name = display_name.presence || username || "Ace"
    name.split.first(2).map { |part| part.first }.join.upcase
  end

  def adopt_quest(quest)
    goals.find_or_create_by(quest: quest)
  end

  def abandon_quest(quest)
    goals.where(quest: quest).destroy_all
  end

  # Rating methods (RatingService.replace records new ratings)

  # Get all ratings for a specific target
  # @param target [Object] The target to get ratings for
  # @return [ActiveRecord::Relation] The ratings for the target
  def ratings_for(target)
    ratings.where(target: target, archived: false)
  end

  # Get the rating for a specific target on a specific spectrum
  # @param target [Object] The target to get the rating for
  # @param spectrum [Spectrum] The spectrum to get the rating on
  # @return [Rating, nil] The rating or nil if not rated
  def rating_for(target, spectrum)
    ratings.find_by(target: target, spectrum: spectrum, archived: false)
  end

  # Check if the ace has rated a target on a spectrum
  # @param target [Object] The target to check
  # @param spectrum [Spectrum] The spectrum to check
  # @return [Boolean] Whether the ace has rated the target on the spectrum
  def rated?(target, spectrum)
    ratings.active.exists?(target: target, spectrum: spectrum)
  end

  private

  def keep_username
    errors.add :username, "cannot be changed" if username_in_database.present? && will_save_change_to_username?
  end
end
