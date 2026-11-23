require "test_helper"

# A tank's photo gallery (Aquarium#gallery_photos)
class GalleryTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_new_user
    @tank = @user.aquariums.create!(size: 20, water_type: "Freshwater")
  end

  def image = fixture_file_upload("tank.jpg", "image/jpeg")

  test "the owner uploads several photos and they show on the tank page" do
    post gallery_photos_aquarium_url(@tank), params: { photos: [image, image] }
    assert_redirected_to aquarium_url(@tank)
    assert_equal 2, @tank.reload.gallery_photos.count

    get aquarium_url(@tank)
    assert_select "#gallery img[src*='/gallery/']", 2
    assert_select "#gallery a[href$='/full']", 2
  end

  test "thumbnails are cropped and full photos keep their shape" do
    @tank.gallery_photos.attach(image)
    photo = @tank.gallery_photos.first
    get gallery_photo_aquarium_url(@tank, photo.id, :thumb)
    assert_equal [480, 360], Vips::Image.new_from_buffer(response.body, "").then { [_1.width, _1.height] }
    get gallery_photo_aquarium_url(@tank, photo.id, :full)
    assert_equal [40, 30], Vips::Image.new_from_buffer(response.body, "").then { [_1.width, _1.height] } # never enlarged
  end

  test "non-images are refused" do
    post gallery_photos_aquarium_url(@tank), params: { photos: [fixture_file_upload("notes.txt", "text/plain")] }
    assert_match "must be a JPEG", flash[:alert]
    assert_equal 0, @tank.reload.gallery_photos.count
  end

  test "the gallery is capped" do
    limit = Aquarium::GALLERY_LIMIT
    @tank.gallery_photos.attach(Array.new(limit) { image })
    post gallery_photos_aquarium_url(@tank), params: { photos: [image] }
    assert_match "at most #{limit}", flash[:alert]
    assert_equal limit, @tank.reload.gallery_photos.count
  end

  test "the owner deletes a photo or makes it the main photo" do
    @tank.gallery_photos.attach(image)
    photo = @tank.gallery_photos.first

    patch feature_gallery_photo_aquarium_url(@tank, photo.id)
    assert @tank.reload.photo.attached?
    assert_not_equal photo.blob_id, @tank.photo.blob_id   # a copy, not shared

    delete remove_gallery_photo_aquarium_url(@tank, photo.id)
    perform_enqueued_jobs
    assert_equal 0, @tank.reload.gallery_photos.count
    assert @tank.photo.attached?
  end

  test "other people can view a public gallery but not change it" do
    @tank.gallery_photos.attach(image)
    photo = @tank.gallery_photos.first
    delete logout_url
    sign_in_new_user(name: "stranger")

    get aquarium_url(@tank)
    assert_select "#gallery img", 1
    assert_select "#gallery form", 0
    get gallery_photo_aquarium_url(@tank, photo.id, :thumb)
    assert_response :success

    post gallery_photos_aquarium_url(@tank), params: { photos: [image] }
    delete remove_gallery_photo_aquarium_url(@tank, photo.id)
    assert_equal 1, @tank.reload.gallery_photos.count
  end

  test "a private tank's gallery photos are refused to others" do
    @tank.update!(public: false)
    @tank.gallery_photos.attach(image)
    photo = @tank.gallery_photos.first
    delete logout_url

    get gallery_photo_aquarium_url(@tank, photo.id, :thumb)
    assert_redirected_to aquariums_url
  end

  test "a photo id from another tank is not found" do
    other = @user.aquariums.create!(size: 10, water_type: "Freshwater")
    other.gallery_photos.attach(image)
    get gallery_photo_aquarium_url(@tank, other.gallery_photos.first.id, :thumb)
    assert_response :not_found
  end
end
