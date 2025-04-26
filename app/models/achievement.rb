class Achievement < ApplicationRecord
  belongs_to :quest
  belongs_to :target, polymorphic: true
end
