class AddSubstrateToAquariums < ActiveRecord::Migration[7.0]
  def change
    add_column :aquariums, :substrate, :string
  end
end
