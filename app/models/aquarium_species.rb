# One row per species in a tank: "this tank has count of this species"
class AquariumSpecies < ApplicationRecord
  belongs_to :aquarium
  belongs_to :species
  # 0 is allowed so a tank remembers species it used to have (shown greyed out for restocking)
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
