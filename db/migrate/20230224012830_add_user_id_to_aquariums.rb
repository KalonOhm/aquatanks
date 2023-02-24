class AddUserIdToAquariums < ActiveRecord::Migration[7.0]
  def change
    add_column :aquariums, :user_id, :integer
  end
end
