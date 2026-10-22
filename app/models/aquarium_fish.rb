class AquariumFish < ApplicationRecord
  # Rails would infer "aquarium_fishes"; the migration created "aquariums_fishes"
  self.table_name = "aquariums_fishes"

  belongs_to :aquarium
  belongs_to :fish 
  validates :count, presence: true, numericality: { greater_than: 0 }

  
end

