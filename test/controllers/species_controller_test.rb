require "test_helper"

class SpeciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @species = species(:one)
  end

  test "should get index" do
    get species_index_url
    assert_response :success
  end

  test "should show species" do
    get species_url(@species)
    assert_response :success
    assert_match "From Wikipedia", response.body
  end

  test "should show species with only a name" do
    get species_url(species(:two))
    assert_response :success
    assert_select "p", text: /Size/, count: 0
  end

  # --- Official species are read-only; custom species belong to their creator ---

  def custom_attrs = { common_name: "Homebred guppy", category: "fish", preferred_water: "freshwater" }

  test "guests can't add, edit or delete species" do
    get new_species_url
    assert_redirected_to login_url
    assert_no_difference("Species.count") { post species_index_url, params: { species: custom_attrs } }
    assert_no_difference("Species.count") { delete species_url(@species) }
  end

  test "official species can't be edited or deleted, even when logged in" do
    sign_in_new_user
    get edit_species_url(@species)
    assert_redirected_to species_url(@species)
    assert_match "come from Wikipedia", flash[:alert]

    patch species_url(@species), params: { species: { common_name: "Vandalised" } }
    assert_equal "Black tetra", @species.reload.common_name
    assert_no_difference("Species.count") { delete species_url(@species) }
  end

  test "a logged-in user adds a custom species they own" do
    user = sign_in_new_user
    get new_species_url
    assert_response :success

    assert_difference("user.custom_species.count") { post species_index_url, params: { species: custom_attrs } }
    custom = Species.last
    assert_redirected_to species_url(custom)
    assert_not custom.official?
    assert_equal 0, Species.official.where(common_name: "Homebred guppy").count
  end

  test "adding from a tank stocks the new species there" do
    user = sign_in_new_user
    tank = user.aquariums.create!(size: 20, water_type: "Freshwater")
    post species_index_url, params: { aquarium_id: tank.id, species: custom_attrs }
    assert_redirected_to aquarium_url(tank)
    assert_equal ["Homebred guppy"], tank.species.pluck(:common_name)
  end

  test "the owner edits and deletes their custom species; others can't" do
    owner = sign_in_new_user
    custom = owner.custom_species.create!(custom_attrs)
    patch species_url(custom), params: { species: { common_name: "Fancy guppy" } }
    assert_equal "Fancy guppy", custom.reload.common_name

    delete logout_url
    sign_in_new_user(name: "stranger")
    patch species_url(custom), params: { species: { common_name: "Hacked" } }
    assert_equal "Fancy guppy", custom.reload.common_name
    assert_no_difference("Species.count") { delete species_url(custom) }

    delete logout_url
    post login_url, params: { email: owner.email, password: "secret123" }
    assert_difference("Species.count", -1) { delete species_url(custom) }
  end

  test "a custom species is seen by its owner and by viewers of a tank it's in" do
    owner = sign_in_new_user
    custom = owner.custom_species.create!(custom_attrs)
    tank = owner.aquariums.create!(size: 20, water_type: "Freshwater", public: false)
    tank.aquarium_species.create!(species: custom, count: 1)

    get species_index_url, params: { q: "homebred" }
    assert_equal ["Homebred guppy"], css_select("#species h5").map(&:text)

    delete logout_url
    sign_in_new_user(name: "stranger")
    get species_url(custom)
    assert_redirected_to species_index_url      # only in a private tank
    get species_index_url, params: { q: "homebred" }
    assert_empty css_select("#species h5")
    get search_species_url, params: { term: "homebred" }
    assert_empty response.parsed_body

    tank.update!(public: true)
    get species_url(custom)
    assert_response :success
    assert_match "Custom species, added by #{owner.name}", response.body
  end

  test "nobody can stock someone else's custom species" do
    owner = User.create!(name: "otherowner", email: "other@ex.com", password: "secret123")
    custom = owner.custom_species.create!(custom_attrs)
    user = sign_in_new_user
    tank = user.aquariums.create!(size: 20, water_type: "Freshwater")
    post add_species_aquarium_url(tank), params: { species_id: custom.id }
    assert_response :not_found
    assert_empty tank.species
  end

  test "index filters by search, category and water" do
    get species_index_url, params: { q: "black", category: "fish" }
    assert_equal ["Black tetra"], css_select("#species h5").map(&:text)

    get species_index_url, params: { water: "saltwater" }
    assert_equal ["Black urchin"], css_select("#species h5").map(&:text)
  end

  test "search matches aliases" do
    get search_species_url, params: { term: "skirt" }
    assert_equal [@species.id], response.parsed_body.map { |result| result["id"] }
    assert_equal "Black tetra", response.parsed_body.first["text"]
  end

  test "search puts species suited to the tank's water first" do
    get search_species_url, params: { term: "black", water: "saltwater" }
    assert_equal ["Black urchin", "Black tetra"], response.parsed_body.map { |result| result["text"] }
    assert_equal [true, false], response.parsed_body.map { |result| result["suits_water"] }
    assert_equal "Saltwater invertebrate", response.parsed_body.first["kind"]
  end

  test "search needs at least two characters" do
    get search_species_url, params: { term: "b" }
    assert_equal [], response.parsed_body
  end
end
