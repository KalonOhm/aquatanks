require "application_system_test_case"

# Search-as-you-type on the tank page (app/javascript/controllers/species_search_controller.js)
class SpeciesSearchTest < ApplicationSystemTestCase
  setup do
    user = User.create!(name: "tankowner", email: "owner@example.com", password: "secret123")
    @tank = user.aquariums.create!(size: 20, water_type: "Saltwater")

    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: "secret123"
    click_button "Login" # the nav also has a Login link
    assert_text "Login successful"
  end

  test "typing finds species, tank's water first, and picking one adds it" do
    visit aquarium_url(@tank)
    assert_button "Add to Tank", disabled: true

    fill_in "Add a species", with: "black"
    within "[data-species-search-target='results']" do
      assert_selector "button", count: 2
      assert_selector "button:first-child", text: "Black urchin"
      assert_text "doesn't match this tank's water", count: 1 # the freshwater tetra
      click_on "Black urchin"
    end

    fill_in "count", with: 2
    click_on "Add to Tank"
    assert_text "Added 2 Black urchin."
    assert_selector "h2", text: "Invertebrates"
  end

  test "shows when nothing matches" do
    visit aquarium_url(@tank)
    fill_in "Add a species", with: "zzzz"
    assert_text "No matches"
    assert_button "Add to Tank", disabled: true
  end
end
