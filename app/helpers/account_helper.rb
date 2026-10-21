module AccountHelper
  def ace_avatar(ace)
    color = ace.avatar_color.presence_in(Ace::AVATAR_COLORS.values) || Ace::AVATAR_COLORS.values.first
    tag.span ace.initials, class: "ace-avatar", style: "background-color: #{color}", aria: { hidden: true }
  end

  def ace_identity(ace)
    tag.span class: "ace-identity" do
      ace_avatar(ace) + tag.span {
        tag.span(ace.public_name, class: "ace-display-name") +
          (ace.handle ? tag.span(ace.handle, class: "ace-handle") : "")
      }
    end
  end

  def account_card(title, description, &block)
    content_for :title, title
    tag.section class: "account-card", aria: { labelledby: "account-title" } do
      tag.header(class: "account-heading") {
        tag.span(icon("bolt", size: 24), class: "account-mark") +
          tag.p("Athlete Ace", class: "eyebrow") +
          tag.h1(title, id: "account-title", class: "page-title") +
          tag.p(description, class: "account-description")
      } + capture(&block)
    end
  end

  def account_field(form, attribute, type:, label: nil, hint: nil, **options)
    hint_id = "#{form.object_name}_#{attribute}_hint"
    options[:aria] = { describedby: hint_id } if hint
    tag.div class: "account-field" do
      safe_join [
        form.label(attribute, label),
        form.public_send("#{type}_field", attribute, **options, class: "account-input"),
        (tag.p(hint, id: hint_id, class: "account-hint") if hint)
      ].compact
    end
  end

  def account_password_hint
    "At least #{@minimum_password_length} characters." if @minimum_password_length
  end
end
