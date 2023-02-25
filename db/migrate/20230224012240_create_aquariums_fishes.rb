class CreateAquariumsFishes < ActiveRecord::Migration[7.0]
  def change
    create_table :aquariums_fishes do |t|
      t.belongs_to :aquarium
      t.belongs_to :fish

      t.timestamps
    end
  end
end
