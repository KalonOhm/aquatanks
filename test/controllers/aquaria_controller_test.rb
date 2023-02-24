require "test_helper"

class AquariumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @aquarium = aquariums(:one)
  end

  test "should get index" do
    get aquariums_url
    assert_response :success
  end

  test "should get new" do
    get new_aquarium_url
    assert_response :success
  end

  test "should create aquarium" do
    assert_difference("Aquarium.count") do
      post aquariums_url, params: { aquarium: { filter: @aquarium.filter, plants: @aquarium.plants, size: @aquarium.size, user_id: @aquarium.user_id, water_type: @aquarium.water_type } }
    end

    assert_redirected_to aquarium_url(Aquarium.last)
  end

  test "should show aquarium" do
    get aquarium_url(@aquarium)
    assert_response :success
  end

  test "should get edit" do
    get edit_aquarium_url(@aquarium)
    assert_response :success
  end

  test "should update aquarium" do
    patch aquarium_url(@aquarium), params: { aquarium: { filter: @aquarium.filter, plants: @aquarium.plants, size: @aquarium.size, user_id: @aquarium.user_id, water_type: @aquarium.water_type } }
    assert_redirected_to aquarium_url(@aquarium)
  end

  test "should destroy aquarium" do
    assert_difference("Aquarium.count", -1) do
      delete aquarium_url(@aquarium)
    end

    assert_redirected_to aquariums_url
  end
end
