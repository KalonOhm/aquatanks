module SpeciesHelper
  # Shown when a species has no picture, or its picture fails to load
  PLACEHOLDER_IMAGE = "fishbowl-clipart-acquarium-15.png"

  # The onerror swap uses inline JS, so it would need allowing if a
  # Content Security Policy is ever turned on
  def species_image_tag(species, **options)
    placeholder = image_path(PLACEHOLDER_IMAGE)
    image_tag species.image_url.presence || placeholder,
      alt: species.common_name,
      onerror: "this.onerror=null;this.src='#{placeholder}'",
      **options
  end

  CATEGORY_HEADINGS = {
    "fish" => "Fish",
    "invertebrate" => "Invertebrates",
    "plant" => "Plants",
    "amphibian" => "Amphibians",
  }.freeze

  # Whether to lead with the scientific name (the "scientific names first"
  # preference, when the species has one)
  def scientific_first?(species)
    preferences.scientific_names_first && species.taxonomic_name.present?
  end

  # The name to show first
  def species_name(species)
    scientific_first?(species) ? species.taxonomic_name : species.common_name
  end

  # The other name, or nil when there isn't a different one
  def species_other_name(species)
    other = scientific_first?(species) ? species.common_name : species.taxonomic_name
    other unless other.blank? || other == species_name(species)
  end

  # "Freshwater plant", "Saltwater invertebrate", ...
  def species_kind(species)
    [species.preferred_water&.sub("_water", ""), species.category].compact_blank.join(" ").capitalize
  end
end
