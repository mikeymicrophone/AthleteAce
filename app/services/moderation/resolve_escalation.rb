module Moderation
  class ResolveEscalation
    def self.call(escalation:, actor:, resolution:, reason:, version:)
      raise Review::Forbidden, "An admin must resolve escalations." unless actor.admin?
      subject = escalation.subject
      if subject
        subject.with_lock(requires_new: true) { resolve_locked(escalation, subject, actor, resolution, reason, version) }
      else
        resolve_locked(escalation, nil, actor, resolution, reason, version)
      end
    end

    def self.resolve_locked(escalation, subject, actor, resolution, reason, version)
      escalation.with_lock(requires_new: true) do
        if escalation.subject_ace_id == actor.id || escalation.requested_by_id == actor.id
          raise Review::Forbidden, "Another admin must resolve this escalation."
        end
        if subject.is_a?(ShoutOut) && subject.shout_out_reports.open.where(reporter_id: actor.id).exists?
          raise Review::Forbidden, "Another admin must decide your report."
        end
        reason = reason.to_s.strip
        if escalation.resolved_at?
          return escalation if escalation.resolved_by_id == actor.id && escalation.resolution == resolution && escalation.resolution_reason == reason && escalation.lock_version == version + 1
          raise Review::Conflict, "Another admin already resolved this escalation."
        end
        raise Review::Conflict, "This escalation changed. Reload before resolving." unless escalation.lock_version == version
        raise ArgumentError, "Choose an escalation resolution." unless ModerationEscalation::RESOLUTIONS.key?(resolution)
        raise ArgumentError, "Give a resolution reason of at most 2000 characters." if reason.blank? || reason.length > 2000
        unless resolution == "no_change"
          raise Review::Conflict, "The content changed or no longer exists. Close without changes, then inspect the current case." unless escalation.current_content?
          Review.call(record: subject, actor: actor, action: resolution, revision: escalation.revision,
            status: escalation.captured_status, reason: reason, escalation: escalation)
        end
        escalation.update!(resolution: resolution, resolution_reason: reason, resolved_by: actor, resolved_at: Time.current)
        escalation
      end
    end
    private_class_method :resolve_locked
  end
end
