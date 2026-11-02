require "test_helper"

# How each preference changes what a signed-in user sees
class PreferencesTest < ActionDispatch::IntegrationTest
  test "metric users see and enter tank volumes in litres" do
    user = sign_in_new_user(units: "metric")
    post aquariums_url, params: { aquarium: { size: "100", water_type: "Freshwater" } }
    tank = user.aquariums.last
    assert_in_delta 26.42, tank.size, 0.01 # stored in gallons

    get aquarium_url(tank)
    assert_match "100 L", response.body
    get edit_aquarium_url(tank)
    assert_select "input[name='aquarium[size]'][value='100.0']"
  end

  test "default water filters the catalog until the user picks Any" do
    sign_in_new_user(default_water: "saltwater")
    get species_index_url
    assert_equal ["Black urchin"], css_select("#species h5").map(&:text)

    get species_index_url, params: { water: "" }
    assert_equal 3, css_select("#species h5").size
  end

  test "scientific names first" do
    sign_in_new_user(scientific_names_first: true)
    get species_index_url
    assert_includes css_select("#species h5").map(&:text), "Gymnocorymbus ternetzi"

    get search_species_url, params: { term: "skirt" }
    assert_equal({ "text" => "Gymnocorymbus ternetzi", "other_name" => "Black tetra" },
                 response.parsed_body.first.slice("text", "other_name"))
  end

  test "strict search only returns species for the tank's water" do
    get search_species_url, params: { term: "black", water: "saltwater", strict: "1" }
    assert_equal ["Black urchin"], response.parsed_body.map { |result| result["text"] }
  end

  test "the theme preference reaches the page" do
    get species_index_url
    assert_select "html:not(.dark)" # guests follow their device (set by the script)
    assert_select "meta[name=aquatanks-theme][content=system]"

    sign_in_new_user(theme: "dark")
    get species_index_url
    assert_select "html.dark"
    assert_select "meta[name=aquatanks-theme][content=dark]"
  end
end
