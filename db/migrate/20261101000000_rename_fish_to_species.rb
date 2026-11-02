# The catalog now holds invertebrates, plants and amphibians as well as fish, so
# "fishes" becomes "species". Renaming (rather than recreating) keeps every
# existing row, including which species are stocked in which tanks.
class RenameFishToSpecies < ActiveRecord::Migration[8.1]
  OLD_PLACEHOLDER = "https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/60610/empty-aquarium-clipart-md.png"

  def up
    rename_table :fishes, :species
    rename_table :aquariums_fishes, :aquarium_species
    rename_column :aquarium_species, :fish_id, :species_id

    add_column :species, :category, :string, null: false, default: "fish"
    add_index :species, :category

    # A blank image_url now means "no picture"; the view picks the placeholder
    change_column_default :species, :image_url, from: OLD_PLACEHOLDER, to: nil
    execute "UPDATE species SET image_url = NULL WHERE image_url = '#{OLD_PLACEHOLDER}'"

    # Extra common names, so a species can be found by any of them
    create_table :species_aliases do |t|
      t.references :species, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :species_aliases, :name
  end

  def down
    drop_table :species_aliases

    execute "UPDATE species SET image_url = '#{OLD_PLACEHOLDER}' WHERE image_url IS NULL"
    change_column_default :species, :image_url, from: nil, to: OLD_PLACEHOLDER

    remove_index :species, :category
    remove_column :species, :category

    rename_column :aquarium_species, :species_id, :fish_id
    rename_table :aquarium_species, :aquariums_fishes
    rename_table :species, :fishes
  end
end
