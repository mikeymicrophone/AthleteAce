class GameAttempt < ApplicationRecord
  belongs_to :ace
  belongs_to :subject_entity, polymorphic: true
  belongs_to :target_entity, polymorphic: true
  belongs_to :chosen_entity, polymorphic: true, optional: true
end
