class TeamPalette
  LIGHT_TEXT = "#FFFFFF".freeze
  DARK_TEXT = "#131418".freeze

  def self.valid_color?(value)
    value.is_a?(String) && value.match?(/\A#[0-9a-f]{6}\z/i)
  end

  # Compare contrast in linear sRGB once when saving a palette, not while rendering it.
  def self.text_color(background)
    return unless valid_color?(background)

    luminance = relative_luminance(background)
    light_contrast = 1.05 / (luminance + 0.05)
    dark_contrast = (luminance + 0.05) / (relative_luminance(DARK_TEXT) + 0.05)
    light_contrast >= dark_contrast ? LIGHT_TEXT : DARK_TEXT
  end

  def self.relative_luminance(color)
    channels = color.delete_prefix("#").scan(/../).map do |part|
      value = part.to_i(16) / 255.0
      value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    channels.zip([ 0.2126, 0.7152, 0.0722 ]).sum { |channel, weight| channel * weight }
  end
  private_class_method :relative_luminance
end
