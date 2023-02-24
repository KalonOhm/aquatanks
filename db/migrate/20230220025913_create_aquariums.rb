class CreateAquariums < ActiveRecord::Migration[7.0]
  def change
    create_table :aquariums do |t|
      t.integer :size
      t.string :water_type
      t.string :filter
      t.boolean :plants

      t.timestamps
    end
  end
end
