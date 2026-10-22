class ShoutOutSubmission
  def self.call(draft:, revision:, bid_cents:, payment_method:)
    raise ArgumentError, "Choose credit or Stripe." unless %w[credit stripe].include?(payment_method)
    raise ArgumentError, "Direct payments must be between $0.50 and $999,999.99." if payment_method == "stripe" && !bid_cents.between?(50, 99_999_999)
    draft.with_lock(requires_new: true) do
      raise ArgumentError, "This draft changed. Reload it before submitting." unless draft.lock_version == revision
      existing = draft.shout_outs.find_by(draft_revision: revision)
      if existing
        unless existing.bid_cents == bid_cents && existing.payment_method == payment_method
          raise ArgumentError, "This draft version was already submitted. Edit and save a new version to change its bid."
        end
        return existing
      end
      raise ActiveRecord::RecordInvalid, draft unless draft.valid?
      team = draft.target.is_a?(Team) ? draft.target : draft.target.team
      post = draft.shout_outs.create!(created_by: draft.ace, target: draft.target, target_name: draft.target.name,
        team_id: team&.id, league_id: team&.league_id, message: draft.message, draft_revision: revision,
        bid_cents: bid_cents, payment_method: payment_method)
      post.reserve_credit! if payment_method == "credit"
      post
    end
  end
end
