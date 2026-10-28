module TeamPaletteHelper
  def team_palette_style(primary, text, secondary = nil, prefix: "team")
    return unless TeamPalette.valid_color?(primary) && [ TeamPalette::LIGHT_TEXT, TeamPalette::DARK_TEXT ].include?(text)

    style = "--#{prefix}-color: #{primary}; --#{prefix}-ink: #{text};"
    style += " --#{prefix}-secondary: #{secondary};" if TeamPalette.valid_color?(secondary)
    style
  end
end
