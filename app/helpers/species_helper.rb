module SpeciesHelper
  # Shown when a species has no picture, or its picture fails to load
  PLACEHOLDER_IMAGE = "fishbowl-clipart-acquarium-15.png"

  # The onerror swap uses inline JS, so it would need allowing if a
  # Content Security Policy is ever turned on
  # "Custom" badge with its owner, or the Wikipedia source line, for a species page or card
  def species_source(species, short: false)
    if species.official?
      return if short
      tag.p(class: "text-xs text-gray-500 dark:text-neutral-400") do
        safe_join(["From Wikipedia's aquarium species lists. Spot a mistake? See the ", link_to("FAQ", faq_path, class: "underline"), "."])
      end
    else
      tag.span(short ? "Custom" : "Custom species, added by #{species.user.name}",
        class: "inline-block rounded bg-amber-100 px-1.5 py-0.5 text-xs text-amber-900 dark:bg-amber-900 dark:text-amber-100")
    end
  end

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
