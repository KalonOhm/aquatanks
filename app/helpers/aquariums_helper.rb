module AquariumsHelper
  PLACEHOLDER_TANK_IMAGE = "https://img.clipartlook.com/easy-free-clipart-aquarium-clipart-191_165.gif".freeze

  # The tank's uploaded photo at a pre-sized variant (:card or :large, see
  # Aquarium), or the clipart when there isn't one.
  def tank_photo_tag(aquarium, variant: :card, **options)
    alt = "#{aquarium.user.name}'s aquarium"
    if aquarium.photo.attached? && aquarium.photo.blob.persisted?
      image_tag aquarium.photo.variant(variant), alt: alt, **options
    else
      image_tag PLACEHOLDER_TANK_IMAGE, alt: alt, **options
    end
  end
end
