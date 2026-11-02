# Another common name for a species, e.g. "skirt tetra" for the Black tetra
class SpeciesAlias < ApplicationRecord
  belongs_to :species

  validates :name, presence: true
end
