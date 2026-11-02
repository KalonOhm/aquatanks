# Converts tank volumes between the stored unit (US gallons) and the viewer's
# preferred units (User#units: "us" or "metric")
module Units
  LITRES_PER_GALLON = 3.78541

  def self.to_gallons(value, units)
    return value if value.blank?
    units == "metric" ? (value.to_d / LITRES_PER_GALLON.to_d).round(2) : value.to_d
  end

  def self.from_gallons(gallons, units)
    return gallons if gallons.nil?
    units == "metric" ? gallons.to_d * LITRES_PER_GALLON.to_d : gallons.to_d
  end
end
