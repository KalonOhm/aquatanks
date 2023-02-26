require "test_helper"

class FishControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fish = fish(:one)
  end

  test "should get index" do
    get fishes_url
    assert_response :success
  end

  test "should get new" do
    get new_fish_url
    assert_response :success
  end

  test "should create fish" do
    assert_difference("Fish.count") do
      post fishes_url, params: { fish: { common_name: @fish.common_name, image_url: @fish.image_url, other_remarks: @fish.other_remarks, size: @fish.size, taxonomic_name: @fish.taxonomic_name } }
    end

    assert_redirected_to fish_url(Fish.last)
  end

  test "should show fish" do
    get fish_url(@fish)
    assert_response :success
  end

  test "should get edit" do
    get edit_fish_url(@fish)
    assert_response :success
  end

  test "should update fish" do
    patch fish_url(@fish), params: { fish: { common_name: @fish.common_name, image_url: @fish.image_url, other_remarks: @fish.other_remarks, size: @fish.size, taxonomic_name: @fish.taxonomic_name } }
    assert_redirected_to fish_url(@fish)
  end

  test "should destroy fish" do
    assert_difference("Fish.count", -1) do
      delete fish_url(@fish)
    end

    assert_redirected_to fishes_url
  end
end
