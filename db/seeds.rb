# Seeds the fish catalog by scraping Wikipedia's aquarium fish lists.
# Safe to re-run: existing fish are matched on name + water type and updated in place.
#
#   ruby bin/rails db:seed

require 'nokogiri'
require 'open-uri'

class FishScraper
  SCRAPE_URL = "https://en.wikipedia.org/wiki/List_of_"
  # Wikipedia asks scrapers to identify themselves
  USER_AGENT = "AquatanksSeeder/1.0 (personal hobby project)"

  PAGES = {
    "freshwater_aquarium_fish_species" => "freshwater",
    "brackish_aquarium_fish_species"   => "brackish_water",
    "marine_aquarium_fish_species"     => "saltwater",
  }

  # Each page (and some tables within a page) order and name columns differently,
  # so columns are found by header text rather than by position.
  COLUMNS = {
    common_name:    /common name/i,
    taxonomic_name: /scientific name|taxonomy|binomial/i,
    image:          /image|picture|photo/i,
    size:           /\A(max\.?\s*)?size\z/i,
    other_remarks:  /remarks|description/i,
  }

  def self.scrape_all
    PAGES.flat_map { |page, water| scrape(page, water) }
  end

  def self.scrape(page, preferred_water)
    doc = Nokogiri::HTML(URI.open(SCRAPE_URL + page, "User-Agent" => USER_AGENT))

    fish_tables = doc.css('table').select do |table|
      table.at_css('tr')&.css('th')&.any? { |th| th.text =~ COLUMNS[:common_name] }
    end

    fish_tables.flat_map do |table|
      header_row, *rows = table.css('tr')
      headers = header_row.css('th').map { |th| th.text.strip }
      index = COLUMNS.transform_values { |pattern| headers.index { |h| h =~ pattern } }

      rows.filter_map do |row|
        cells = row.css('td')
        # skip header rows, blank rows, and family-name divider rows (one cell spanning the table)
        next if row.css('th').any? || cells.size != headers.size

        text = ->(column) { index[column] && clean(cells[index[column]].text) }
        common_name = text.(:common_name)
        taxonomic_name = text.(:taxonomic_name)
        next if common_name.blank? && taxonomic_name.blank?

        {
          common_name: common_name.presence || taxonomic_name,
          taxonomic_name: taxonomic_name,
          image_url: index[:image] && image_url(cells[index[:image]]),
          size: text.(:size).presence,
          other_remarks: text.(:other_remarks).presence,
          preferred_water: preferred_water,
        }
      end
    end
  end

  # strip citation markers like "[12]" and collapse whitespace/newlines
  def self.clean(text)
    text.gsub(/\[\d+\]/, '').gsub(/\s+/, ' ').strip
  end

  # image srcs are protocol-relative ("//upload.wikimedia.org/...") with tracking params
  def self.image_url(cell)
    src = cell.at_css('img')&.[]('src')
    return nil if src.blank?
    src = "https:#{src}" if src.start_with?('//')
    src.split('?').first
  end
end

fishes_master_list = FishScraper.scrape_all

Fish.transaction do
  fishes_master_list.each do |attrs|
    fish = Fish.find_or_initialize_by(attrs.slice(:common_name, :taxonomic_name, :preferred_water))
    # leave the column's default placeholder in place when the row has no image
    fish.update!(attrs.compact)
  end
end

puts "Seeded #{fishes_master_list.size} fish (#{Fish.count} total in database)"
