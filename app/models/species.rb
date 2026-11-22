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
  # Only checks the URL's shape: no network requests at validation time (seeding
  # saves ~2200 species). Pictures that fail to load fall back to a placeholder in the view.
  validate :image_url_is_http
  before_validation :normalize_image_url

  # Every word of the term must appear somewhere in the common name, scientific
  # name or an alias, in any order and as part of a word: "amazon sword",
  # "sword amazon" and "amaz swo" all find "Amazon sword". Case-insensitive.
  #
  # Typos: a word that appears in no name at all is swapped for the closest-spelled
  # words in the catalog (see similar_words), so "anubius" finds Anubias.
  def self.search(term)
    term.to_s.split.reduce(all) do |scope, word|
      words = name_matches(word).exists? ? [word] : similar_words(word)
      next none if words.empty?

      scope.merge(words.map { name_condition(_1) }.reduce(:or))
    end
  end

  # Catalog words (from names and aliases) within a small spelling distance of
  # word: one letter off for 4–7 letters, two for longer. Shorter words aren't
  # fuzzed, as nearly everything is one letter away from them. Only the closest
  # distance found is kept, so a near miss doesn't drown in looser ones.
  def self.similar_words(word)
    word = word.downcase
    max = word.length >= 8 ? 2 : 1
    return [] if word.length < 4

    by_distance = vocabulary.filter_map do |candidate|
      next if (candidate.length - word.length).abs > max
      distance = DidYouMean::Levenshtein.distance(word, candidate)
      [candidate, distance] if distance <= max
    end
    best = by_distance.map(&:last).min
    by_distance.select { _2 == best }.map(&:first)
  end

  # Every distinct lowercase word of 4+ letters in the names and aliases. Only
  # built when a word has no match, and cheap at catalog size (a few thousand words).
  def self.vocabulary
    names = unscoped.pluck(:common_name, :taxonomic_name).flatten + SpeciesAlias.pluck(:name)
    names.compact.flat_map { _1.downcase.scan(/[[:alpha:]]{4,}/) }.uniq
  end

  def self.name_matches(word)
    name_condition(word)
  end

  def self.name_condition(word)
    unscoped.where(<<~SQL, pattern: "%#{sanitize_sql_like(word)}%")
      species.common_name LIKE :pattern
      OR species.taxonomic_name LIKE :pattern
      OR EXISTS (SELECT 1 FROM species_aliases
                 WHERE species_aliases.species_id = species.id AND species_aliases.name LIKE :pattern)
    SQL
  end
  private_class_method :name_matches, :name_condition

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

  private

    # Protocol-relative URLs ("//upload.wikimedia.org/...") become https
    def normalize_image_url
      url = image_url.to_s.strip
      url = "https:#{url}" if url.start_with?("//")
      self.image_url = url.presence
    end

    def image_url_is_http
      return if image_url.blank?
      uri = URI.parse(image_url)
      valid = uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      valid = false
    ensure
      errors.add(:image_url, "must be an http or https URL") unless image_url.blank? || valid
    end

    def has_a_name
      if common_name.blank? && taxonomic_name.blank?
        errors.add(:base, "Give a common name or a scientific name")
      end
    end
end
