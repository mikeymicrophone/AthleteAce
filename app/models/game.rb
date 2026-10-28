class Game < Contest
  before_validation { self.kind ||= "game" }
  validates :kind, inclusion: { in: [ "game" ] }
end
