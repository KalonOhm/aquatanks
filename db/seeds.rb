# Seeds the species catalog (fish, invertebrates, plants, amphibians) by scraping
# Wikipedia's aquarium species lists.
# Safe to re-run: existing species are matched on name + water type + category and updated in place.
#
#   ruby bin/rails db:seed

require 'nokogiri'
require 'open-uri'

class SpeciesScraper
  SCRAPE_URL = "https://en.wikipedia.org/wiki/List_of_"
  # Wikipedia asks scrapers to identify themselves
  USER_AGENT = "AquatanksSeeder/1.0 (personal hobby project)"

  # page => [preferred_water, category]
  PAGES = {
    "freshwater_aquarium_fish_species"         => ["freshwater",     "fish"],
    "brackish_aquarium_fish_species"           => ["brackish_water", "fish"],
    "marine_aquarium_fish_species"             => ["saltwater",      "fish"],
    "freshwater_aquarium_invertebrate_species" => ["freshwater",     "invertebrate"],
    "marine_aquarium_invertebrate_species"     => ["saltwater",      "invertebrate"],
    "freshwater_aquarium_plant_species"        => ["freshwater",     "plant"],
    "marine_aquarium_plant_species"            => ["saltwater",      "plant"],
    "freshwater_aquarium_amphibian_species"    => ["freshwater",     "amphibian"],
  }

  # Each page (and some tables within a page) order and name columns differently,
  # so columns are found by header text rather than by position.
  COLUMNS = {
    common_name:    /common name/i,
    taxonomic_name: /scientific name|taxonomy|binomial|\Aspecies\z/i,
    genus:          /\Agenus\z/i, # fallback when the Species cell is "?"
    image:          /image|picture|photo/i,
    size:           /\A(max\.?\s*)?size\b/i, # "Size", "Max size (bell diameter)", not "Tank size"
    other_remarks:  /remarks|description|notes/i,
  }

  # What the tables put in a cell instead of leaving it empty
  BLANK = /\A(none|n\/a|\?|-|—|unknown)\z/i

  # Commas, semicolons and " or " separate alternative names, except inside
  # parentheses ("Siamese fighting fish (sometimes Betta, esp. US)").
  # Slashes are left alone: they usually join half-names ("catfish/corydoras").
  NAME_SEPARATOR = /\s*(?:,\s*or\s+|,|;|\s+or\s+)(?![^(]*\))\s*/
  # In genus lists "or" joins two adjectives sharing a noun ("Crinkled or ruffled
  # aponogeton"), so splitting there would leave a name of just "Crinkled"
  GENUS_LIST_NAME_SEPARATOR = /\s*[,;]\s*/

  def self.scrape_all
    PAGES.flat_map { |page, (water, category)| scrape(page, water, category) }
  end

  def self.scrape(page, preferred_water, category)
    doc = Nokogiri::HTML(URI.open(SCRAPE_URL + page, "User-Agent" => USER_AGENT))

    species_tables = doc.css('table').select do |table|
      table.at_css('tr')&.css('th')&.any? { |th| th.text =~ COLUMNS[:common_name] }
    end

    species_tables.flat_map do |table|
      header_row, *rows = grid(table)
      headers = header_row.map { |th| clean(th.text) }
      index = COLUMNS.transform_values { |pattern| headers.index { |h| h =~ pattern } }

      rows.flat_map do |cells|
        # skip header rows, blank or short rows, and family-name divider rows (one cell spanning the table)
        next [] if cells.any? { |c| c.name == 'th' } || cells.size != headers.size || cells.uniq.size == 1

        text = ->(column) { index[column] && value(cells[index[column]].text) }
        shared = {
          image_url: index[:image] && image_url(cells[index[:image]]),
          size: text.(:size),
          other_remarks: text.(:other_remarks),
          preferred_water: preferred_water,
          category: category,
        }

        species_cell = index[:taxonomic_name] && cells[index[:taxonomic_name]]
        if species_cell&.at_css('li')
          # Some plant rows list a whole genus in one cell, one species per line:
          # "Anubias afzelii (Narrow-leafed anubias)". The row's image is of just
          # one of them, so the expanded species don't get it.
          next genus_list(species_cell).filter_map do |taxonomic_name, common_text|
            species_attrs(common_text, taxonomic_name, shared.merge(image_url: nil), separator: GENUS_LIST_NAME_SEPARATOR)
          end
        end

        common_text = index[:common_name] ? clean(cells[index[:common_name]].text) : ""
        [species_attrs(common_text, text.(:taxonomic_name) || text.(:genus), shared)].compact
      end
    end
  end

  def self.species_attrs(common_text, taxonomic_name, shared, separator: NAME_SEPARATOR)
    names = common_text.split(separator).map { |n| value(n.sub(/\A"(.*)"\z/, '\1')) }.compact.uniq
    return nil if names.empty? && taxonomic_name.blank?

    shared.merge(
      common_name: names.first || taxonomic_name,
      aliases: names.drop(1) - [taxonomic_name],
      # what older seeds stored as the name, before it was split into aliases
      old_common_name: common_text.presence || taxonomic_name,
      taxonomic_name: taxonomic_name,
    )
  end

  # [[scientific name, common names text], ...] from a cell listing many species.
  # Entries are list items, but one cell runs them together with "*" instead.
  def self.genus_list(cell)
    cell.css('li').flat_map { |li| clean(li.text).split('*') }.filter_map do |entry|
      taxonomic_name = value(entry[/\A[^(]*/])
      [taxonomic_name, entry[/\(([^)]*)\)/, 1].to_s] if taxonomic_name
    end
  end

  # Turns the table into rows of cells, copying a cell that spans several rows
  # (rowspan) or columns (colspan) into each position it covers, so a column
  # index always lines up. The plant/invertebrate/amphibian pages merge Genus
  # cells down the rows of each genus.
  def self.grid(table)
    spanning = {} # column => [cell, rows still to fill]
    table.css('tr').map do |tr|
      cells = tr.element_children.select { |el| %w[th td].include?(el.name) }
      row = []
      while cells.any? || spanning[row.size]
        if spanning[row.size]
          cell, rows_left = spanning[row.size]
          rows_left > 1 ? spanning[row.size] = [cell, rows_left - 1] : spanning.delete(row.size)
          row << cell
        else
          cell = cells.shift
          rowspan = [cell['rowspan'].to_i, 1].max
          [cell['colspan'].to_i, 1].max.times do
            spanning[row.size] = [cell, rowspan - 1] if rowspan > 1
            row << cell
          end
        end
      end
      row
    end
  end

  # strip footnote markers like "[12]", "[a]", "[citation needed]" and collapse whitespace/newlines
  def self.clean(text)
    text.gsub(/\[(\d+|[a-z]|citation needed)\]/i, '').gsub(/\s+/, ' ').strip
  end

  # cleaned text, or nil when the cell is empty or a placeholder like "N/A"
  def self.value(text)
    text = clean(text)
    text unless text.empty? || text.match?(BLANK)
  end

  # image srcs are protocol-relative ("//upload.wikimedia.org/...") with tracking params
  def self.image_url(cell)
    src = cell.at_css('img')&.[]('src')
    return nil if src.blank?
    src = "https:#{src}" if src.start_with?('//')
    src.split('?').first
  end
end

species_master_list = SpeciesScraper.scrape_all

Species.transaction do
  species_master_list.each do |attrs|
    match = attrs.slice(:taxonomic_name, :preferred_water, :category)
    species = Species.find_by(match.merge(common_name: attrs[:common_name])) ||
              Species.find_by(match.merge(common_name: attrs[:old_common_name])) ||
              Species.new(match)
    # .compact: a value missing from Wikipedia this time doesn't wipe one saved earlier
    species.assign_attributes(attrs.except(:aliases, :old_common_name).compact)
    species.alias_names = attrs[:aliases]
    species.save!
  end
end

puts "Scraped #{species_master_list.size} rows (#{Species.count} species in database)"
Species.group(:category).count.each { |category, n| puts "  #{category}: #{n}" }
