class Fish < ApplicationRecord
  has_many :aquariums_fishes
  has_many :aquariums, through: :aquariums_fishes

  #validate :image_url_exists

  # def image_url_exists 
  #   #is the url valid
  #   #is the content type an image
  #   require 'open-uri'

  #   begin 
  #     path = URI.open(image_url)
  #     errors.add(:image_url, "does not contain image content") and return unless path.content_type.starts_with?("image")
  #   rescue 
  #     errors.add(:image_url, "invalid url")
  #   end
  # end
  
end
