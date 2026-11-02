# User preferences (edited on the profile page) and per-tank privacy.
# Tank size becomes a decimal so volumes entered in litres survive the
# conversion to gallons (whole gallons would drift: 100 L -> 26 gal -> 98 L).
class AddPreferences < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.integer :per_page, null: false, default: 25
      t.string :units, null: false, default: "us"
      t.string :theme, null: false, default: "system"
      t.string :default_water # nil = any water type
      t.boolean :scientific_names_first, null: false, default: false
      t.boolean :strict_add_search, null: false, default: false
      t.boolean :default_tank_public, null: false, default: true
    end

    # existing tanks stay visible, as they were before privacy existed
    add_column :aquariums, :public, :boolean, null: false, default: true

    reversible do |dir|
      dir.up { change_column :aquariums, :size, :decimal, precision: 8, scale: 2 }
      dir.down { change_column :aquariums, :size, :integer }
    end
  end
end
