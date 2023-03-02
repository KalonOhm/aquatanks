class AquariumsFishesController < ApplicationController
belongs_to :aquarium
belongs_to :fish 
validates :count, presence: true, numericality: { greater_than: 0 }

end
