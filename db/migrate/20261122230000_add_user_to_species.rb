# Custom species: a user's own additions. Scraped (official) species have no user.
class AddUserToSpecies < ActiveRecord::Migration[8.1]
  def change
    add_reference :species, :user, foreign_key: true, null: true
  end
end
