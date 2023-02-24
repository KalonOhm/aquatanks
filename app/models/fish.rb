class Fish < ApplicationRecord
  has_many :aquariums_fishes
  has_many :aquariums, :through => :aquariums_fishes

  validates 
  
end
