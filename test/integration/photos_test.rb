require "test_helper"

# Tank photos and user avatars (Active Storage, see HasPhoto)
class PhotosTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_new_user
    @tank = @user.aquariums.create!(size: 20, water_type: "Freshwater")
  end

  def image = fixture_file_upload("tank.jpg", "image/jpeg")

  test "uploading a tank photo shows it instead of the clipart" do
    patch aquarium_url(@tank), params: { aquarium: { photo: image } }
    assert @tank.reload.photo.attached?

    get aquarium_url(@tank)
    assert_select "img[src*='/photo/']"

    get user_url(@user)   # only this user's tank, unlike All Tanks
    assert_select "#aquariums img[src*='/photo/']"
    assert_select "#aquariums img[src*='clipartlook']", count: 0
  end

  test "a tank without a photo shows the clipart" do
    get aquariums_url
    assert_select "#aquariums img[src*='clipartlook']"
  end

  test "the remove box drops the photo" do
    @tank.update!(photo: image)
    patch aquarium_url(@tank), params: { aquarium: { remove_photo: "1" } }
    assert_not @tank.reload.photo.attached?
  end

  test "a new upload wins over the remove box" do
    @tank.update!(photo: image)
    patch aquarium_url(@tank), params: { aquarium: { photo: image, remove_photo: "1" } }
    assert @tank.reload.photo.attached?
  end

  test "only images are accepted" do
    patch aquarium_url(@tank), params: { aquarium: { photo: fixture_file_upload("notes.txt", "text/plain") } }
    assert_response :unprocessable_entity
    assert_not @tank.reload.photo.attached?
  end

  test "an avatar set on the profile shows on the user's page and tank cards" do
    patch user_url(@user), params: { user: { avatar: image } }
    assert @user.reload.avatar.attached?

    get user_url(@user)
    assert_select "img[alt='#{@user.name}'][src*='/avatar/']"
    get aquariums_url
    assert_select "#aquariums img[alt='#{@user.name}']"
  end

  test "without an avatar the initial is shown" do
    get user_url(@user)
    assert_select "span.rounded-full", text: "T"
  end

  test "photos are served after a visibility check" do
    @tank.update!(photo: image)
    get photo_aquarium_url(@tank, :card)
    assert_response :success
    assert_equal "image/jpeg", response.media_type
    assert_equal [576, 432], Vips::Image.new_from_buffer(response.body, "").then { [_1.width, _1.height] }
  end

  test "a private tank's photo is refused to other people" do
    @tank.update!(photo: image, public: false)
    delete logout_url
    get photo_aquarium_url(@tank, :card)
    assert_redirected_to aquariums_url

    sign_in_new_user(name: "stranger")
    get photo_aquarium_url(@tank, :card)
    assert_redirected_to aquariums_url
  end

  test "private photos aren't cached for others, public ones are" do
    @tank.update!(photo: image, public: false)
    get photo_aquarium_url(@tank, :card)
    assert_match "private", response.headers["Cache-Control"]

    @tank.update!(public: true)
    get photo_aquarium_url(@tank, :card)
    assert_match "public", response.headers["Cache-Control"]
  end

  test "unknown variants and missing photos are not found" do
    @tank.update!(photo: image)
    get photo_aquarium_url(@tank, :huge)
    assert_response :not_found
    get avatar_user_url(@user, :small)
    assert_response :not_found
  end

  test "Active Storage's own links aren't served" do
    @tank.update!(photo: image)
    assert_raises(NoMethodError) { rails_blob_path(@tank.photo) }
    get "/rails/active_storage/blobs/redirect/#{@tank.photo.blob.signed_id}/tank.jpg"
    assert_response :not_found
  end
end
