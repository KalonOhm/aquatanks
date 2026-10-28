class Aquarium < ApplicationRecord
  belongs_to :user
  has_many :aquariums_fishes, class_name: "AquariumFish", dependent: :destroy
  has_many :fishes, through: :aquariums_fishes

end
