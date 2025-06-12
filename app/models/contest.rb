class Contest < ApplicationRecord
  belongs_to :context, polymorphic: true
  belongs_to :champion, class_name: 'Team', optional: true
  belongs_to :season, optional: true
  
  serialize :contestant_ids, coder: JSON
  serialize :comments, coder: JSON
end
