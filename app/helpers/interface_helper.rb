module InterfaceHelper
  def browse_header title, &block
    tag.header class: "browse-header" do
      tag.div do
        tag.p("Browse", class: "eyebrow") + tag.h1(title, class: "page-title")
      end + tag.div(class: "page-actions", &block)
    end
  end

  def entity_link record
    return "" unless record

    link_to record, class: "entity-chip", data: { entity: record.model_name.singular } do
      icon_for_resource(record.model_name.singular, size: 16) + tag.span(record.name)
    end
  end

  def entity_avatar record, size: :small
    image_url = record.is_a?(Player) ? record.photo_url : record.logo_url
    initials = record.name.split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span class: "entity-avatar entity-avatar-#{size}", data: {
      entity: record.model_name.singular, controller: "entity-image"
    } do
      fallback = tag.span initials, class: "entity-initials", data: { entity_image_target: "fallback" }
      image = if image_url.present?
        tag.img src: image_url, alt: "", class: "entity-portrait hidden",
          data: { entity_image_target: "image", action: "load->entity-image#loaded error->entity-image#failed" }
      end
      safe_join [fallback, image].compact
    end
  end

  def record_identity record
    tag.div class: "record-identity" do
      entity_avatar(record) + tag.div do
        tag.p(record.model_name.human, class: "eyebrow entity-kind", data: { entity: record.model_name.singular }) +
          link_to(record.name, record, class: "identity-name")
      end
    end
  end
end
