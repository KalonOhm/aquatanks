class CreateAquaria < ActiveRecord::Migration[7.0]
  def change
    create_table :aquaria do |t|
      t.integer :size
      t.string :water_type
      t.string :filter
      t.boolean :plants
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
