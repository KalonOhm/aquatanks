# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Fish.delete_all
ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='fishes'")

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

        common_name = cell[0]&.text
        taxonomic_name = cell[1]&.text
        image_src = (cell[2]&.css('img')&.first&.[]('src')||'')
        if image_src != ""
          image_url = "http:" + image_src
        else
          image_url = nil
        end
        # use "safe navigation operator" (`&.`)
        size = (cell[3]&.text&.split[1])#&.gsub(/\((\d+(\.\d+)?)\s*in\)/, '\1')
        # need to remove "()" and possibly in
        other_remarks = (cell[4]&.text).gsub(/\n/, '')
        # need to remove \n chars.

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks,
          preferred_water: "freshwater"
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
        
        common_name = cell[0]&.text
        taxonomic_name = cell[1]&.text
        image_src = ((cell[2]&.css('img')||[]).first&.[]('src')||'')
        if image_src != ""
          image_url = "http:" + image_src
        else
          image_url = nil
        end
        # use "safe navigation operator" (`&.`)
        size = (cell[3]&.text||'')&.gsub(/\((\d+\.\d+)\s*in\)|"|\s+in/, '\1')
        # need to remove "()" and possibly in
        other_remarks = (cell[4]&.text||'').gsub(/\n/, '')
        # need to remove \n chars.

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks,
          preferred_water: "brackish_water",
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
        
        common_name = cell[0]&.text
        taxonomic_name = cell[2]&.text
        image_src = (cell[1]&.css('img')&.first&.[]('src')||'')
        if image_src != ""
          image_url = "http:" + image_src
        else
          image_url = nil
        end
        # use "safe navigation operator" (`&.`)
        size = (cell[-1]&.text&.split[1])#&.gsub(/\((\d+(\.\d+)?)\s*in\)/, '\1')
        # need to remove "()" and possibly in
        other_remarks = (cell[4]&.text).gsub(/\n/, '')

        fish = {
          common_name: common_name,
          taxonomic_name: taxonomic_name,
          image_url: image_url,
          size: size,
          other_remarks: other_remarks,
          preferred_water: "saltwater"
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
  Fish.create!(fish)
end
# puts fishes_master_list

# fishes_master_list.each do |fish|
#   puts fish[:common_name]
#   puts fish[:taxonomic_name]
#   puts fish[:image_url]
#   puts fish[:size]
#   puts fish[:other_remarks]
#   puts fish[:preferred_water]
# end

# Fish.create!([

# sampleFish = ([
#   {
#   common_name: "Guppy",
#   taxonomic_name: "Poecilia reticulata",
#   image_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Aspidoras_fuscoguttatus.jpg/175px-Aspidoras_fuscoguttatus.jpg",
#   size: "3cm",
#   other_remarks: "Will breed like rabbits",
#   preferred_water: "brackish_water"
# },
# {
#   common_name: "Brown-Point Shield Skin",
#   taxonomic_name: "Aspidoras fuscoguttatus",
#   image_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Aspidoras_fuscoguttatus.jpg/175px-Aspidoras_fuscoguttatus.jpg",
#   size: "3.8cm",
#   other_remarks: "",
#   preferred_water: "freshwater"
# },
# ])
# puts sampleFish
# Aquarium.destroy_all
# User.destroy_all


  


