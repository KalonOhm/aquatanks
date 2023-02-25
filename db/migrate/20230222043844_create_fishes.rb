class CreateFishes < ActiveRecord::Migration[7.0]
  def change
    create_table :fishes do |t|
      t.string :common_name
      t.string :taxonomic_name
      t.string :image_url, default: "https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/60610/empty-aquarium-clipart-md.png"
      t.string :size
      t.string :other_remarks

      t.timestamps
    end
  end
end
