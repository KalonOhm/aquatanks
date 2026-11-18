require "test_helper"

class OwnerLinkTest < ActionDispatch::IntegrationTest
  test "tank list and tank page link the owner to their page" do
    owner = sign_in_new_user(default_tank_public: true)
    tank = owner.aquariums.create!(size: 20, water_type: Aquarium::WATER_TYPES.keys.first, public: true)

    get aquariums_url
    assert_select "a[href=?]", user_path(owner), text: owner.name

    get user_url(owner)
    assert_select "a[href=?]", user_path(owner), text: owner.name

    get aquarium_url(tank)
    assert_select "h1 a[href=?]", user_path(owner), text: owner.name
  end
end
