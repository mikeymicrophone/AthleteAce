module Moderation
  class Review
    class Conflict < StandardError; end
    class Forbidden < StandardError; end
    ACTIONS = { "approve" => "approved", "reject" => "rejected", "hide" => "hidden", "reopen" => "pending" }.freeze

    def self.call(record:, actor:, action:, revision:, status:, reason: nil, escalation: nil)
      raise Forbidden, "Review requires a moderator or admin." unless actor.can_moderate?
      raise Forbidden, "Another reviewer must decide your submission." if record.created_by_id == actor.id
      destination = ACTIONS.fetch(action) { raise ArgumentError, "Unknown review action" }
      raise ArgumentError, "Give a reason for this decision." if %w[reject hide].include?(action) && reason.blank?
      raise ArgumentError, "The reason is too long." if reason.to_s.length > 2000

      record.with_lock(requires_new: true) do
        open_escalation = ModerationEscalation.open.find_by(subject: record)
        if open_escalation && (!actor.admin? || escalation&.id != open_escalation.id)
          raise Forbidden, "This submission is escalated. An admin must resolve it through Escalations."
        end
        if record.is_a?(ShoutOut) && action == "hide" && record.shout_out_reports.open.where(reporter_id: actor.id).exists?
          raise Forbidden, "Another reviewer must decide your report."
        end
        if record.moderation_revision != revision || record.moderation_status != status
          raise Conflict, "This item changed or another reviewer already decided it. Reload before reviewing."
        end
        allowed = case action
        when "approve", "reject" then %w[pending]
        when "hide" then %w[approved]
        when "reopen" then %w[rejected hidden]
        end
        raise Conflict, "This action does not apply to the current status." unless allowed.include?(record.moderation_status)
        if action == "approve" && record.is_a?(Highlight) && (!record.quest.approved? || !record.achievement.approved?)
          raise Conflict, "Approve the linked quest and achievement first."
        end
        record.settle_review!(action) if record.is_a?(ShoutOut)
        previous = record.moderation_status
        record.update!(moderation_status: destination)
        record.moderation_decisions.create!(actor: actor, action: action == "reopen" ? "reopened" : destination,
          from_status: previous, to_status: destination, revision: revision, reason: reason, snapshot: record.moderation_snapshot)
        if record.is_a?(ShoutOut) && action == "hide"
          record.shout_out_reports.open.update_all(resolution: "hidden", decision_reason: reason, resolved_by_id: actor.id,
            resolved_at: Time.current, updated_at: Time.current)
        end
      end
      record
    end
  end
end
