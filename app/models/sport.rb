class Sport < ApplicationRecord
  has_many :leagues
  has_many :conferences, through: :leagues
  has_many :divisions, through: :conferences
  has_many :memberships, through: :divisions
  has_many :teams, through: :memberships
  has_many :players, through: :teams
  has_many :positions, dependent: :destroy
  
  def create_standard_positions positions_data
    positions_data.each do |pos_data|
      positions.find_or_create_by!(name: pos_data[:name]) do |p|
        p.abbreviation = pos_data[:abbreviation] if pos_data[:abbreviation].present?
        p.description = pos_data[:description] if pos_data[:description].present?
      end
    end
  end
  
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  def self.ransackable_associations auth_object = nil
    ["leagues", "players", "positions", "teams"]
  end
end
