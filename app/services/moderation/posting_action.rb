module Moderation
  class PostingAction
    def self.allowed?(actor, ace)
      actor.can_moderate? && actor.id != ace.id && !ace.admin? && (actor.admin? || !ace.moderator?)
    end

    def self.call(ace:, actor:, kind:, attributes:)
      ace.with_lock(requires_new: true) do
        raise Review::Forbidden, "Another authorized reviewer must handle this account." unless allowed?(actor, ace)
        new(ace, actor, attributes).apply(kind)
      end
    end

    def initialize(ace, actor, attributes)
      @ace, @actor, @attributes = ace, actor, attributes
    end

    def apply(kind)
      reason = @attributes[:reason].to_s.strip
      case kind
      when "warn"
        type, id = @attributes[:related_item].to_s.split(":", 2)
        if @attributes[:related_item].present? && (!Queue::TYPES.key?(type) || !id.to_s.match?(/\A[1-9]\d*\z/))
          raise ArgumentError, "Choose a submission by this ace."
        end
        attrs = { reason: reason, subject_type: type.presence, subject_id: id&.to_i }
        record_once(@ace.warnings, attrs) do |values|
          if type.present?
            subject = Queue::TYPES.fetch(type).where(created_by: @ace).find(id)
            raise ArgumentError, "This shout-out has not been funded." if subject.is_a?(ShoutOut) && subject.funding_status == "unfunded"
            values[:subject_name] = subject.is_a?(Highlight) ? "#{subject.achievement.name} in #{subject.quest.name}" : subject.name
          end
          @ace.warnings.create!(values)
        end
      when "mute"
        hours = @attributes[:duration_hours].to_s
        raise ArgumentError, "Choose 24 hours, 7 days or 30 days." unless Mute::DURATIONS.values.map(&:to_s).include?(hours)
        post = @ace.shout_outs.find(@attributes[:hide_post_id]) if @attributes[:hide_post_id].present?
        attrs = { reason: reason, note: @attributes[:note].to_s.strip.presence, duration_hours: hours.to_i, hidden_shout_out_id: post&.id }
        record_once(@ace.mutes, attrs) do |values|
          raise Review::Conflict, "This ace already has an active mute. End it before starting another." if @ace.active_posting_mute
          if post
            post.with_lock do
              raise Review::Conflict, "This shout-out no longer has open reports." unless post.shout_out_reports.open.exists?
              Review.call(record: post, actor: @actor, action: "hide", revision: post.moderation_revision,
                status: "approved", reason: reason)
            end
          end
          now = Time.current
          @ace.mutes.create!(values.merge(starts_at: now, ends_at: now + hours.to_i.hours))
        end
      when "note"
        record_once(@ace.moderator_notes, { body: @attributes[:body].to_s.strip }) { |values| @ace.moderator_notes.create!(values) }
      when "end_mute"
        mute = @ace.mutes.find(@attributes[:mute_id])
        return mute if mute.ended_at?
        raise Review::Conflict, "This mute has already expired." unless mute.active?
        mute.update!(ended_at: Time.current, ended_by: @actor, end_reason: reason)
        mute
      else
        raise ArgumentError, "Choose a posting moderation action."
      end
    end

    private

    def record_once(relation, attributes)
      values = attributes.merge(moderator_id: @actor.id, request_key: @attributes[:request_key].to_s)
      existing = relation.find_by(request_key: values[:request_key])
      if existing
        raise Review::Conflict, "This action changed. Reload before submitting again." unless values.all? { |key, value| existing.public_send(key) == value }
        return existing
      end
      yield values
    end
  end
end
