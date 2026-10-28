# Swatches and samples for the design reference pages (config/routes/design.rb)
module DesignHelper
  COLOR_TOKENS = {
    "Ground" => %w[ground surface surface-2 surface-3 line line-2 ink-3 ink-2 ink edge scrim],
    "Shell" => %w[shell shell-2 shell-3 shell-line shell-ink-2 shell-ink],
    "Status" => %w[ok ok-ink ok-tint on-ok bad bad-ink bad-tint warn warn-ink warn-tint warn-hot info info-ink info-tint],
    "Charts" => %w[chart-1 chart-2 chart-3 chart-grid chart-axis track],
    "Shadow colors" => %w[shadow-near shadow-far]
  }.freeze

  SIDES = {
    "play" => "Play · Volt",
    "feed" => "Feed · Flare",
    "mod" => "Moderate · Harbor",
    "admin" => "Admin · Chalk"
  }.freeze

  # Mirrors the data-entity map in app/assets/tailwind/variables/tokens.css
  ENTITY_FAMILIES = {
    "people" => %w[player position role contract],
    "clubs" => %w[team organization organization_affiliation],
    "competition" => %w[sport league conference division membership federation],
    "places" => %w[stadium city state country residence jurisdiction],
    "time" => %w[year season campaign activation contest contestant]
  }.freeze

  def token_section title, &block
    tag.section class: "flex flex-col gap-3" do
      tag.h2(title, class: "font-display text-section uppercase") + capture(&block)
    end
  end

  def type_sample text, classes, spec
    tag.div class: "flex flex-col gap-1" do
      tag.span(text, class: classes) + tag.span(spec, class: "text-xs text-ink-3")
    end
  end

  def swatch_grid tokens
    tag.div class: "grid grid-cols-[repeat(auto-fill,minmax(6.5rem,1fr))] gap-3" do
      safe_join tokens.map { |token| color_swatch token }
    end
  end

  def color_swatch token
    tag.div class: "flex flex-col gap-1.5" do
      tag.span(class: "h-12 rounded-lg ring-1 ring-line ring-inset", style: "background: var(--color-#{token})") +
        tag.code(token, class: "font-mono text-xs text-ink-2")
    end
  end

  def side_sample side, label
    tag.div data: { side: side }, class: "flex flex-col gap-2 rounded-tool bg-accent-tint p-3" do
      tag.span(label, class: "self-start rounded-full bg-accent px-3 py-1 text-sm font-semibold text-on-accent") +
        tag.span("Links and icons", class: "text-sm font-semibold text-accent-text")
    end
  end

  def entity_family_row family, models
    tag.div class: "flex flex-wrap items-center gap-2" do
      tag.span(family.capitalize, class: "w-28 font-semibold", style: "color: var(--color-entity-#{family})") +
        safe_join(models.map { |model| entity_sample model })
    end
  end

  def entity_sample model
    tag.span model.humanize, data: { entity: model },
             class: "rounded-full border border-current px-2.5 py-0.5 text-xs font-semibold text-(--entity-color)"
  end

  def radius_sample radius_class, label
    tag.div class: "flex flex-col items-center gap-1.5" do
      tag.span(class: "block size-14 bg-surface-3 #{radius_class}") + tag.code(label, class: "font-mono text-xs text-ink-3")
    end
  end
end
