class Division < ApplicationRecord
  include Ratable
  
  belongs_to :conference
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  has_one :league, through: :conference
  has_many :campaigns, through: :teams
  has_many :contestants, through: :campaigns
  has_many :contests, through: :contestants
  has_many :contracts, through: :teams
  has_many :activations, through: :contracts
  
  validates :name, presence: true
  
  def display_name
    if abbreviation.present?
      "#{name} (#{abbreviation})"
    else
      name
    end
  end
  
  
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
  
end
