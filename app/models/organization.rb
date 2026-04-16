class Organization < ApplicationRecord
  has_many :organization_affiliations, dependent: :destroy
  has_many :teams, through: :organization_affiliations
  has_many :current_organization_affiliations, -> { current }, class_name: "OrganizationAffiliation"
  has_many :current_teams, through: :current_organization_affiliations, source: :team

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    column_names
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end
end
