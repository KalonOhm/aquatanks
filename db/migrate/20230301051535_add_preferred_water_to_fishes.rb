class AddPreferredWaterToFishes < ActiveRecord::Migration[7.0]
  def change
    add_column :fishes, :preferred_water, :string
  end
end
