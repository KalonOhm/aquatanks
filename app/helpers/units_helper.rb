# Shows measurements in the viewer's preferred units (User#units)
module UnitsHelper
  # "20 gallons" or "76 L"
  def tank_volume(aquarium)
    return if aquarium.size.nil?
    volume = Units.from_gallons(aquarium.size, preferences.units).round(1)
    volume = volume.to_i if volume == volume.to_i
    preferences.metric? ? "#{volume} L" : pluralize(volume, "gallon")
  end

  # Tank form label: "Tank Volume (litres)"
  def volume_unit_name
    preferences.metric? ? "litres" : "gallons"
  end

  # One measurement, optionally a range: "33", "4–5.5", "3.8-5.1"
  MEASURE = /[\d.]+(?:\s*[–-]\s*[\d.]+)?\s*(?:cm|mm|in)\b/
  # A measurement with its conversion in brackets: "33 cm (13.0 in)"
  MEASURE_PAIR = /(#{MEASURE})\s*\((#{MEASURE})\)/

  # Wikipedia gives most sizes in both units, "33 cm (13.0 in)"; show just the
  # preferred half of each such pair. Anything else is shown as written.
  def species_size(species)
    # Wikipedia separates numbers from units with non-breaking spaces
    species.size.tr(" ", " ").gsub(MEASURE_PAIR) do
      first, second = $1, $2
      metric_first = first.match?(/(cm|mm)\z/)
      preferences.metric? == metric_first ? first : second
    end
  end
end
