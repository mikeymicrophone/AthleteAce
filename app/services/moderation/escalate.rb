module Moderation
  class Escalate
    def self.call(subject:, actor:, reason:, request_key:, revision: nil, status: nil)
      raise Review::Forbidden, "Escalation requires a reviewer." unless actor.can_moderate?
      subject.with_lock(requires_new: true) do
        owner_id = subject.is_a?(Ace) ? subject.id : subject.created_by_id
        raise Review::Forbidden, "Another reviewer must handle your account or submission." if owner_id == actor.id
        reason = reason.to_s.strip
        existing = ModerationEscalation.find_by(requested_by: actor, request_key: request_key)
        if existing
          unless existing.subject_type == subject.class.name && existing.subject_id == subject.id && existing.reason == reason
            raise Review::Conflict, "This request changed. Reload before escalating again."
          end
          return existing
        end
        if ModerationEscalation.open.exists?(subject: subject)
          raise Review::Conflict, "This case already has an open escalation."
        end
        unless subject.is_a?(Ace)
          if subject.moderation_revision != revision || subject.moderation_status != status
            raise Review::Conflict, "This submission changed. Reload before escalating."
          end
          if subject.is_a?(ShoutOut) && subject.funding_status == "unfunded"
            raise Review::Conflict, "Unfunded shout-outs cannot enter moderation."
          end
        end
        snapshot = subject.is_a?(Ace) ? subject.attributes.slice("username", "display_name", "admin", "moderator") : subject.moderation_snapshot
        snapshot["funding_status"] = subject.funding_status if subject.is_a?(ShoutOut)
        name = if subject.is_a?(Ace)
          subject.public_name
        elsif subject.is_a?(Highlight)
          "#{subject.achievement.name} in #{subject.quest.name}"
        else
          subject.name
        end
        ModerationEscalation.create!(subject: subject, subject_ace_id: owner_id, requested_by: actor, reason: reason,
          request_key: request_key, snapshot: snapshot, subject_name: name,
          revision: subject.is_a?(Ace) ? nil : subject.moderation_revision,
          captured_status: subject.is_a?(Ace) ? nil : subject.moderation_status)
      end
    rescue ActiveRecord::RecordNotUnique
      raise Review::Conflict, "An escalation was recorded concurrently. Reload before trying again."
    end
  end
end
