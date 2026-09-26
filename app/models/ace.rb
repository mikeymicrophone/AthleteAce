class Ace < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable
         
  has_many :goals, dependent: :destroy
  has_many :active_goals, -> { Goal.active }, class_name: 'Goal'
  has_many :quests, through: :goals
  has_many :ratings, dependent: :destroy
  has_many :game_attempts, dependent: :destroy
  has_many :created_quests, class_name: "Quest", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify

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
end
