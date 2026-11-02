class Species < ApplicationRecord
  CATEGORIES = %w[fish invertebrate plant amphibian].freeze
  WATER_TYPES = %w[freshwater brackish_water saltwater].freeze

  # deleting a species from the catalog also removes it from every tank
  has_many :aquarium_species, dependent: :destroy
  has_many :aquariums, through: :aquarium_species
  has_many :aliases, class_name: "SpeciesAlias", dependent: :destroy

  # Everything but a name is optional; views show only the fields that are filled in
  validates :category, inclusion: { in: CATEGORIES }
  validates :preferred_water, inclusion: { in: WATER_TYPES }, allow_blank: true
  validate :has_a_name

  # Every word of the term must appear somewhere in the common name, scientific
  # name or an alias, in any order and as part of a word: "amazon sword",
  # "sword amazon" and "amaz swo" all find "Amazon sword". Case-insensitive.
  def self.search(term)
    term.to_s.split.reduce(all) do |scope, word|
      scope.where(<<~SQL, pattern: "%#{sanitize_sql_like(word)}%")
        species.common_name LIKE :pattern
        OR species.taxonomic_name LIKE :pattern
        OR EXISTS (SELECT 1 FROM species_aliases
                   WHERE species_aliases.species_id = species.id AND species_aliases.name LIKE :pattern)
      SQL
    end
  end

  def alias_names
    aliases.map(&:name)
  end

  # Replaces the aliases with these names (blanks and repeats dropped)
  def alias_names=(names)
    names = names.map(&:strip).reject(&:blank?).uniq
    self.aliases = names.map { |name| aliases.detect { |a| a.name == name } || SpeciesAlias.new(name: name) }
  end

  # Aliases as comma-separated text, for the species form
  def alias_list
    alias_names.join(", ")
  end

  def alias_list=(text)
    self.alias_names = text.to_s.split(",")
  end

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

  private

    def has_a_name
      if common_name.blank? && taxonomic_name.blank?
        errors.add(:base, "Give a common name or a scientific name")
      end
    end
end
