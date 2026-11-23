require "test_helper"

# The tank page: adding species and how the stocked list is shown
class StockingTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "tankowner", email: "owner@example.com", password: "secret123")
    @tank = @user.aquariums.create!(size: 20, water_type: "Freshwater")
    post login_url, params: { email: @user.email, password: "secret123" }
  end

  test "stocked species are grouped by category" do
    post add_species_aquarium_url(@tank), params: { species_id: species(:two).id, count: 3 }
    post add_species_aquarium_url(@tank), params: { species_id: species(:one).id }

    get aquarium_url(@tank)
    assert_equal ["Fish", "Plants"], css_select("h2").map(&:text) - ["Gallery"]
    assert_match "3 × ", response.body
  end

  test "the add form searches with the tank's water type" do
    get aquarium_url(@tank)
    assert_select "[data-controller='species-search'][data-species-search-water-value='freshwater']"
    assert_select "input[type=submit][value='Add to Tank'][disabled]"
  end

  test "a plant at zero says none left" do
    @tank.aquarium_species.create!(species: species(:two), count: 0)
    get aquarium_url(@tank)
    assert_match "(none left)", response.body
  end

  test "stock that doesn't suit the tank's water is flagged" do
    saltwater = species(:three)
    @tank.aquarium_species.create!(species: saltwater, count: 2)
    @tank.aquarium_species.create!(species: species(:one), count: 1)

    get aquarium_url(@tank)
    assert_match "1 stocked species prefers different water", response.body
    assert_match "Prefers saltwater; this is a freshwater tank.", response.body
    assert_select "p", text: /Prefers freshwater/, count: 0
  end

  test "no warning when everything suits, or the mismatch has died out" do
    @tank.aquarium_species.create!(species: species(:three), count: 0)
    get aquarium_url(@tank)
    assert_no_match "prefers different water", response.body
  end
end
