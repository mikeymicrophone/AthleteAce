class ShoutOutReactionSummary
  def initialize(posts:, ace:)
    ids = posts.map(&:id)
    reactions = ShoutOutReaction.where(shout_out_id: ids)
    @counts = reactions.group(:shout_out_id, :kind).count
    @selected = ace ? reactions.where(ace: ace).pluck(:shout_out_id, :kind).to_set : Set.new
  end

  def count(post, kind)
    @counts.fetch([ post.id, kind ], 0)
  end

  def selected?(post, kind)
    @selected.include?([ post.id, kind ])
  end
end
