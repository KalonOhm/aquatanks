class AquariumFish < ApplicationRecord
  belongs_to :aquarium
  belongs_to :fish 
end

