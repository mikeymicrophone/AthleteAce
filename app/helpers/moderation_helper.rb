module ModerationHelper
  def moderation_notice(record)
    return if record.approved?

    tag.aside class: "moderation-notice", role: "status" do
      text = if record.moderation_status == "pending"
        "In review. Only you and reviewers can see this submission."
      elsif record.moderation_status == "rejected"
        "This submission was rejected. #{record.moderation_decisions.where(action: 'rejected').order(id: :desc).first&.reason}"
      else
        "This content is hidden."
      end
      tag.p(text)
    end
  end

  def moderation_item_name(record)
    record.is_a?(Highlight) ? "#{record.achievement.name} in #{record.quest.name}" : record.name
  end
end
