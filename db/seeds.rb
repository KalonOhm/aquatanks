# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


Fish.destroy_all

require 'pry'
require 'nokogiri'
require 'open-uri'

class FishScraper 
  SCRAPE_URL = "https://en.wikipedia.org/wiki/List_of_"
  def self.scrape_freshwater
    scrape_url = SCRAPE_URL + "freshwater_aquarium_fish_species"
    doc = Nokogiri::HTML(URI.open(scrape_url))
    
      fish_rows = doc.css('table.wikitable.sortable tbody tr')
     row_count = fish_rows.count

     freshwater_aquarium_fish_species = []

      fish_rows[1..row_count].each do |fish_row|
        # skip headers (th)
        next if fish_row.css('th').any?
        cell = fish_row.css('td')

        common_name = cell[0].text
        taxonomic_name = cell[1].text
        image_url = "https:" + cell[2].css('img').first['src']
        # somehow need to remove first 2 // only
        size = cell[3].text.split[1]
        # need to remove "()" and possibly in
        other_remarks = cell[4].text
        # need to remove \n chars.

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks
        }

        freshwater_aquarium_fish_species << fish
     end
    return freshwater_aquarium_fish_species
  end

  def self.scrape_brackish_water
    scrape_url = SCRAPE_URL + "brackish_aquarium_fish_species"

    doc = Nokogiri::HTML(URI.open(scrape_url)) 
    
    fish_rows = doc.css('table.sortable.collapsible tbody tr')
     row_count = fish_rows.count

     brackish_aquarium_fish_species = []

      fish_rows[1..row_count].each do |fish_row|
        # skip headers (th)
        next if fish_row.css('th').any?
        cell = fish_row.css('td')
        
        common_name = cell[0].text
        taxonomic_name = cell[1].text
        image_url = "https:" + cell[2].css('img').first['src']
        # somehow need to remove first 2 // only
        size = cell[3].text.split[1]
        # need to remove "()" and possibly in
        other_remarks = cell[4].text
        # need to remove \n chars.

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks
        }

        brackish_aquarium_fish_species << fish
      end
      return brackish_aquarium_fish_species

  end
  
  def self.scrape_saltwater
    scrape_url = SCRAPE_URL + "marine_aquarium_fish_species"

    doc = Nokogiri::HTML(URI.open(scrape_url))


    fish_rows = doc.css('table.sortable.collapsible tbody tr')
     row_count = fish_rows.count

     marine_aquarium_fish_species = []


      fish_rows[1..row_count].each do |fish_row|
        # skip headers (th)
        next if fish_row.css('th').any?
        cell = fish_row.css('td')
        
        common_name = cell[0].text
        taxonomic_name = cell[2].text
        image_url = "https:" + cell[1].css('img').first['src']
        # somehow need to remove first 2 // only
        size = cell[5].text.split[1]
        # need to remove "()" and possibly in
        other_remarks = cell[4].text
        # need to remove \n chars.

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks
        }

        marine_aquarium_fish_species << fish
    end
    return marine_aquarium_fish_species
  end
end

#run each scraper
freshwater_aquarium_fish_species = FishScraper.scrape_freshwater
brackish_aquarium_fish_species = FishScraper.scrape_brackish_water
marine_aquarium_fish_species = FishScraper.scrape_saltwater

#combine master fish list
fishes_master_list = freshwater_aquarium_fish_species + brackish_aquarium_fish_species + marine_aquarium_fish_species

fishes_master_list.each do |fish|
  Fish.create!(
    common_name: fish[:common_name],
    taxonomic_name: fish[:taxonomic_name],
    image_url: fish[:image_url],
    size: fish[:size],
    other_remarks: fish[:other_remarks],
  )
end


Fish.create!([
  {
  common_name: "Guppy",
  taxonomic_name: "Poecilia reticulata",
  image_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Aspidoras_fuscoguttatus.jpg/175px-Aspidoras_fuscoguttatus.jpg",
  size: "3cm",
  other_remarks: "Will breed like rabbits",
},
{
  common_name: "Brown-Point Shield Skin",
  taxonomic_name: "Aspidoras fuscoguttatus",
  image_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Aspidoras_fuscoguttatus.jpg/175px-Aspidoras_fuscoguttatus.jpg",
  size: "3.8cm",
  other_remarks: "",
},
])



# Aquarium.destroy_all

# User.destroy_all


  


