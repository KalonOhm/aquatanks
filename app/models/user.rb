class User < ApplicationRecord
  PER_PAGE_OPTIONS = [10, 25, 50, 100].freeze
  UNITS = { "us" => "US (gallons, inches, °F)", "metric" => "Metric (litres, cm, °C)" }.freeze
  THEMES = { "system" => "Follow my device", "light" => "Light", "dark" => "Dark" }.freeze

  validates :name, :email, presence: true, uniqueness: true, length: {minimum: 4, maximum: 20 }
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  has_secure_password

  # Preferences, set on the profile page. A guest gets User.new, so these
  # column defaults double as the guest settings (see ApplicationHelper#preferences)
  validates :per_page, inclusion: { in: PER_PAGE_OPTIONS }
  validates :units, inclusion: { in: UNITS.keys }
  validates :theme, inclusion: { in: THEMES.keys }
  validates :default_water, inclusion: { in: Species::WATER_TYPES }, allow_blank: true

  # deleting a user also deletes their tanks (and, through Aquarium, what's stocked in them)
  has_many :aquariums, dependent: :destroy

  def metric?
    units == "metric"
  end
end
