module Admin
  class ChangeAccount
    def self.call(ace:, actor:, action:, reason:, password:, request_key:, version:, role: nil)
      Ace.transaction do
        Ace.connection.execute("SELECT pg_advisory_xact_lock(194191, 1)")
        actor.reload
        ace.lock!
        raise Moderation::Review::Forbidden, "An active admin must manage accounts." unless actor.admin? && actor.active_for_authentication?
        raise Moderation::Review::Forbidden, "Another admin must change your account." if actor.id == ace.id
        raise Moderation::Review::Forbidden, "Your current password is incorrect." unless actor.valid_password?(password.to_s)
        raise ArgumentError, "Choose an account action." unless AccountAction::ACTIONS.include?(action)
        reason = reason.to_s.strip
        raise ArgumentError, "Give a reason of at most 2000 characters." if reason.blank? || reason.length > 2000
        raise ArgumentError, "Choose Fan, Moderator or Admin." if action == "role" && !%w[fan moderator admin].include?(role)
        existing = AccountAction.find_by(actor: actor, request_key: request_key)
        if existing
          unless existing.ace_id == ace.id && existing.action == action && existing.reason == reason && (action != "role" || existing.after_state["role"] == role)
            raise Moderation::Review::Conflict, "This account action changed. Reload before trying again."
          end
          return existing
        end
        raise Moderation::Review::Conflict, "This account changed. Reload before acting." unless ace.account_version == version
        before = { "role" => ace.role, "suspended" => ace.suspended? }
        case action
        when "role"
          raise Moderation::Review::Conflict, "This ace already has that role." if ace.role == role
          ace.admin = role == "admin"
          ace.moderator = role == "moderator"
        when "suspend"
          raise Moderation::Review::Conflict, "This account is already suspended." if ace.suspended?
          ace.suspended_at = Time.current
          ace.session_version += 1
        when "reactivate"
          raise Moderation::Review::Conflict, "This account is already active." unless ace.suspended?
          ace.suspended_at = nil
        end
        ace.account_version += 1
        ace.save!
        AccountAction.create!(ace: ace, actor: actor, ace_name: ace.public_name, action: action, reason: reason, request_key: request_key,
          before_state: before, after_state: { "role" => ace.role, "suspended" => ace.suspended? })
      end
    end
  end
end
