require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "deleting a user deletes their tanks and what's stocked in them" do
    user = users(:one)
    aquaria(:one).aquarium_species.create!(species: species(:one), count: 2)

    assert_difference -> { Aquarium.count } => -user.aquariums.count, -> { AquariumSpecies.count } => -1 do
      user.destroy
    end
  end
end
