module Moderation
  class ResolveReports
    def self.call(post:, actor:, action:, revision:, last_report_id:, reason:)
      raise Review::Forbidden, "Review requires a moderator or admin." unless actor.can_moderate?
      raise Review::Forbidden, "Another reviewer must decide your submission." if post.created_by_id == actor.id
      raise ArgumentError, "Choose Keep live or Hide." unless %w[keep hide].include?(action)
      raise ArgumentError, "Give a reason of at most 2000 characters." if reason.blank? || reason.length > 2000
      post.with_lock(requires_new: true) do
        if ModerationEscalation.open.exists?(subject: post)
          raise Review::Forbidden, "An admin must resolve the escalation before deciding reports."
        end
        reports = post.shout_out_reports.open
        raise Review::Forbidden, "Another reviewer must decide your report." if reports.where(reporter_id: actor.id).exists?
        unless post.approved? && post.funding_status == "spent" && post.moderation_revision == revision &&
            reports.exists? && reports.maximum(:id) == last_report_id
          raise Review::Conflict, "The post or its reports changed. Reload before deciding."
        end
        if action == "hide"
          Review.call(record: post, actor: actor, action: "hide", revision: revision, status: "approved", reason: reason)
        else
          reports.update_all(resolution: "kept_live", decision_reason: reason, resolved_by_id: actor.id,
            resolved_at: Time.current, updated_at: Time.current)
        end
      end
    end
  end
end
