require "application_system_test_case"

class AquariumsTest < ApplicationSystemTestCase
  setup do
    @aquarium = aquariums(:one)
  end

  test "visiting the index" do
    visit aquariums_url
    assert_selector "h1", text: "Aquariums"
  end

  test "should create aquarium" do
    visit aquariums_url
    click_on "New aquarium"

    fill_in "Filter", with: @aquarium.filter
    fill_in "Plants", with: @aquarium.plants
    fill_in "Size", with: @aquarium.size
    fill_in "User", with: @aquarium.user_id
    fill_in "Water type", with: @aquarium.water_type
    click_on "Create Aquarium"

    assert_text "Aquarium was successfully created"
    click_on "Back"
  end

  test "should update Aquarium" do
    visit aquarium_url(@aquarium)
    click_on "Edit this aquarium", match: :first

    fill_in "Filter", with: @aquarium.filter
    fill_in "Plants", with: @aquarium.plants
    fill_in "Size", with: @aquarium.size
    fill_in "User", with: @aquarium.user_id
    fill_in "Water type", with: @aquarium.water_type
    click_on "Update Aquarium"

    assert_text "Aquarium was successfully updated"
    click_on "Back"
  end

  test "should destroy Aquarium" do
    visit aquarium_url(@aquarium)
    click_on "Destroy this aquarium", match: :first

    assert_text "Aquarium was successfully destroyed"
  end
end
