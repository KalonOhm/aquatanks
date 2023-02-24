class ChangeFishToFishes < ActiveRecord::Migration[7.0]
  def change
      rename_table :fish, :fishes
  end
end
