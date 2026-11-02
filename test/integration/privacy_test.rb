require "test_helper"

class PrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(name: "otheruser", email: "other@ex.com", password: "secret123")
    @public_tank = @owner.aquariums.create!(size: 10, water_type: "Freshwater", public: true)
    @private_tank = @owner.aquariums.create!(size: 55, water_type: "Saltwater", public: false)
  end

  test "others don't see a private tank anywhere" do
    sign_in_new_user

    get aquariums_url
    assert_select "a[href=?]", aquarium_path(@public_tank)
    assert_select "a[href=?]", aquarium_path(@private_tank), count: 0

    get user_url(@owner)
    assert_select "a[href=?]", aquarium_path(@private_tank), count: 0

    get aquarium_url(@private_tank)
    assert_redirected_to aquariums_url
  end

  test "guests don't see it either" do
    get aquarium_url(@private_tank)
    assert_redirected_to aquariums_url
  end

  test "the owner sees their private tank, marked private" do
    post login_url, params: { email: @owner.email, password: "secret123" }

    get aquariums_url
    assert_select "a[href=?]", aquarium_path(@private_tank)
    assert_select "span", text: "Private"

    get aquarium_url(@private_tank)
    assert_response :success
  end

  test "a new tank starts from the default privacy and water preferences" do
    sign_in_new_user(default_tank_public: false, default_water: "brackish_water")
    get new_aquarium_url
    assert_select "input[type=checkbox][name='aquarium[public]']:not([checked])"
    assert_select "option[selected][value='Brackish Water']"
  end
end
