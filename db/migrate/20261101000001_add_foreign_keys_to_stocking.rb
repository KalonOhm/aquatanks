# Makes the database refuse rows that point at a missing tank, species or user.
# Existing orphans (stocked rows for tanks deleted before Aquarium had
# dependent: :destroy) have to go first, or the keys can't be added.
class AddForeignKeysToStocking < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM aquarium_species WHERE aquarium_id NOT IN (SELECT id FROM aquariums)"
    execute "DELETE FROM aquarium_species WHERE species_id NOT IN (SELECT id FROM species)"
    execute "DELETE FROM aquariums WHERE user_id NOT IN (SELECT id FROM users)"

    add_foreign_key :aquarium_species, :aquariums
    add_foreign_key :aquarium_species, :species
    add_foreign_key :aquariums, :users
  end

  def down
    remove_foreign_key :aquariums, :users
    remove_foreign_key :aquarium_species, :species
    remove_foreign_key :aquarium_species, :aquariums
  end
end
