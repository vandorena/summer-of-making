# frozen_string_literal: true

# Utility for image sanitization and resizing
require "mini_magick"

module ImageSanitizer
  MAX_DIMENSION = 1080

  def self.img_opt(file_path)
    image = MiniMagick::Image.open(file_path)
    if image.width > MAX_DIMENSION || image.height > MAX_DIMENSION
      image.resize "#{MAX_DIMENSION}x#{MAX_DIMENSION}>"
    end
    image.strip
    image.write(file_path)
  end
end
