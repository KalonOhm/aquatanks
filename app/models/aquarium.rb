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
  has_many :aquarium_species, dependent: :destroy
  has_many :species, through: :aquarium_species

  # Public tanks, plus the viewer's own private ones
  scope :visible_to, ->(user) { where(public: true).or(where(user_id: user&.id)) }

  # The tank's water type in Species#preferred_water form: "Brackish Water" => "brackish_water"
  def species_water
    WATER_TYPES[water_type]
  end

  def visible_to?(user)
    public? || self.user == user
  end
end
