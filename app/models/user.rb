class User < ApplicationRecord
  validates :username, :email, presence: true, uniqueness: true, length: {minimum: 4, maximum: 20 }
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  has_secure_password

  has_many :aquariums
  # has_many :aquariums_fishes

end
