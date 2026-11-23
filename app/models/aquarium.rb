class Aquarium < ApplicationRecord
  # Tank form label => the matching Species#preferred_water value
  WATER_TYPES = {
    "Freshwater" => "freshwater",
    "Saltwater" => "saltwater",
    "Brackish Water" => "brackish_water",
  }.freeze

  include HasPhoto

  belongs_to :user
  # The tank's profile picture: card size for lists, large for the tank page
  has_photo :photo, variants: { card: [576, 432], large: [1200, 900] }
  # More photos of the setup and livestock, shown on the tank page. thumb is
  # cropped for the grid; full keeps the whole picture for viewing.
  GALLERY_LIMIT = 30
  has_photos :gallery_photos, limit: GALLERY_LIMIT,
    variants: { thumb: [480, 360], full: { resize_to_limit: [1600, 1600] } }
  has_many :aquarium_species, dependent: :destroy
  has_many :species, through: :aquarium_species

  # Public tanks, plus the viewer's own private ones
  scope :visible_to, ->(user) { where(public: true).or(where(user_id: user&.id)) }

  # The tank's water type in Species#preferred_water form: "Brackish Water" => "brackish_water"
  def species_water
    WATER_TYPES[water_type]
  end

  # Whether a species' preferred water matches this tank's. Unknown on either
  # side counts as suiting, so only a definite mismatch gets flagged.
  def suits?(species)
    species.preferred_water.blank? || species_water.blank? || species.preferred_water == species_water
  end

  def visible_to?(user)
    public? || self.user == user
  end
end
