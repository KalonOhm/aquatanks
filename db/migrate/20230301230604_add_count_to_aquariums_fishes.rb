class AddCountToAquariumsFishes < ActiveRecord::Migration[7.0]
  def change
    add_column :aquariums_fishes, :count, :integer
  end
end
