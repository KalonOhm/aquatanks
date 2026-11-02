require "test_helper"

class SpeciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @species = species(:one)
  end

  test "should get index" do
    get species_index_url
    assert_response :success
  end

  test "should get new" do
    get new_species_url
    assert_response :success
  end

  test "should create species" do
    assert_difference("Species.count") do
      post species_index_url, params: { species: { common_name: @species.common_name, image_url: @species.image_url, other_remarks: @species.other_remarks, size: @species.size, taxonomic_name: @species.taxonomic_name } }
    end

    assert_redirected_to species_url(Species.last)
  end

  test "should show species" do
    get species_url(@species)
    assert_response :success
  end

  test "should show species with only a name" do
    get species_url(species(:two))
    assert_response :success
    assert_select "p", text: /Size/, count: 0
  end

  test "should get edit" do
    get edit_species_url(@species)
    assert_response :success
  end

  test "should update species" do
    patch species_url(@species), params: { species: { common_name: @species.common_name, image_url: @species.image_url, other_remarks: @species.other_remarks, size: @species.size, taxonomic_name: @species.taxonomic_name } }
    assert_redirected_to species_url(@species)
  end

  test "should destroy species" do
    assert_difference("Species.count", -1) do
      delete species_url(@species)
    end

    assert_redirected_to species_index_url
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
