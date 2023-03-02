class Aquarium < ApplicationRecord
  belongs_to :user
  has_many :aquariums_fishes
  has_many :fishes, through: :aquariums_fishes

end
