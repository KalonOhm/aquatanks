# One uploaded picture (Active Storage) with a "remove it" checkbox, size/type
# checks and pre-sized variants. Used for tank photos and user avatars.
#
#   has_photo :photo, variants: { card: [576, 432] }
#
# Each variant is a [width, height] box the image is cropped to fill (shown at
# half that size, so it stays sharp on high-density screens).
module HasPhoto
  extend ActiveSupport::Concern

  # HEIC (iPhone) and JPEG XL aren't here: the libvips that ships with
  # RubyInstaller can't read them, so resizing would fail.
  CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_SIZE = 10.megabytes

  class_methods do
    def has_photo(name, variants:)
      has_one_attached name do |attachable|
        variants.each do |variant, (width, height)|
          attachable.variant variant, resize_to_fill: [width, height], preprocessed: true
        end
      end

      # A checkbox on the form: "remove_photo" = "1" drops the current picture
      attribute :"remove_#{name}", :boolean, default: false
      # (a new upload in the same save wins over the checkbox)
      before_save { @purge_photo = public_send(:"remove_#{name}") && attachment_changes[name.to_s].nil? }
      after_save do
        public_send(name).purge_later if @purge_photo
        public_send(:"remove_#{name}=", false)
      end

      validate do
        file = public_send(name)
        next unless file.attached? && attachment_changes[name.to_s]

        unless CONTENT_TYPES.include?(file.blob.content_type)
          errors.add(name, "must be a JPEG, PNG, WebP or GIF image")
        end
        if file.blob.byte_size > MAX_SIZE
          errors.add(name, "must be under #{MAX_SIZE / 1.megabyte} MB")
        end
      end
    end
  end
end
