# Uploaded pictures (Active Storage) with size/type checks and pre-sized variants.
#
#   has_photo  :photo, variants: { card: [576, 432] }      # one, with a remove checkbox
#   has_photos :gallery_photos, variants: { ... }, limit: 30  # many (tank gallery)
#
# A variant given as [width, height] is a box the image is cropped to fill (shown
# at half that size, so it stays sharp on high-density screens). A hash is passed
# to image_processing as is, e.g. { resize_to_limit: [1600, 1600] } to shrink
# without cropping.
module HasPhoto
  extend ActiveSupport::Concern

  # HEIC (iPhone) and JPEG XL aren't here: the libvips that ships with
  # RubyInstaller can't read them, so resizing would fail.
  CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_SIZE = 10.megabytes

  # The variant options for one entry of a variants: hash
  def self.variant_options(spec)
    spec.is_a?(Hash) ? spec : { resize_to_fill: spec }
  end

  # The type/size problem with one blob, or nil
  def self.blob_error(blob)
    return "must be a JPEG, PNG, WebP or GIF image" unless CONTENT_TYPES.include?(blob.content_type)
    "must be under #{MAX_SIZE / 1.megabyte} MB" if blob.byte_size > MAX_SIZE
  end

  class_methods do
    def has_photos(name, variants:, limit:)
      define_singleton_method(:"#{name}_variants") { variants.keys }

      has_many_attached name do |attachable|
        variants.each do |variant, spec|
          attachable.variant variant, **HasPhoto.variant_options(spec), preprocessed: true
        end
      end

      validate do
        files = public_send(name)
        next unless attachment_changes[name.to_s]

        files.reject(&:persisted?).each do |file|
          if (error = HasPhoto.blob_error(file.blob))
            errors.add(name, "#{file.filename} #{error}")
          end
        end
        errors.add(name, "can have at most #{limit} photos") if files.size > limit
      end
    end

    def has_photo(name, variants:)
      # e.g. Aquarium.photo_variants => [:card, :large], what the photo routes accept
      define_singleton_method(:"#{name}_variants") { variants.keys }

      has_one_attached name do |attachable|
        variants.each do |variant, spec|
          attachable.variant variant, **HasPhoto.variant_options(spec), preprocessed: true
        end
      end

      # A checkbox on the form: "remove_photo" = "1" drops the current picture
      attribute :"remove_#{name}", :boolean, default: false
      # (a new upload in the same save wins over the checkbox)
      before_save { instance_variable_set(:"@purge_#{name}", public_send(:"remove_#{name}") && attachment_changes[name.to_s].nil?) }
      after_save do
        public_send(name).purge_later if instance_variable_get(:"@purge_#{name}")
        public_send(:"remove_#{name}=", false)
      end

      validate do
        file = public_send(name)
        next unless file.attached? && attachment_changes[name.to_s]

        if (error = HasPhoto.blob_error(file.blob))
          errors.add(name, error)
        end
      end
    end
  end
end
