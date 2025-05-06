class Ace < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable
         
  has_many :goals, dependent: :destroy
  has_many :quests, through: :goals
  
  def adopt_quest(quest)
    goals.find_or_create_by(quest: quest)
  end
  
  def abandon_quest(quest)
    goals.where(quest: quest).destroy_all
  end
end
