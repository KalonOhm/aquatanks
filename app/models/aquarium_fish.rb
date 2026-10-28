class AquariumFish < ApplicationRecord
  # Rails would infer "aquarium_fishes"; the migration created "aquariums_fishes"
  self.table_name = "aquariums_fishes"

  belongs_to :aquarium
  belongs_to :fish 
  # 0 is allowed so a tank remembers fish it used to have (shown greyed out for restocking)
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  
end

