require "test_helper"

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_new_user
  end

  test "saves preferences" do
    patch user_url(@user), params: { user: { per_page: 50, units: "metric", theme: "dark", default_water: "saltwater",
                                             scientific_names_first: "1", strict_add_search: "1", default_tank_public: "0" } }
    assert_redirected_to edit_user_url(@user)

    @user.reload
    assert_equal [50, "metric", "dark", "saltwater"], [@user.per_page, @user.units, @user.theme, @user.default_water]
    assert @user.scientific_names_first
    assert @user.strict_add_search
    assert_not @user.default_tank_public
  end

  test "rejects a preference value that isn't offered" do
    patch user_url(@user), params: { user: { per_page: 7 } }
    assert_response :unprocessable_entity
    assert_equal 25, @user.reload.per_page
  end

  test "changing the password needs the current one" do
    patch user_url(@user), params: { user: { password: "newsecret1" } }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("secret123")

    patch user_url(@user), params: { user: { password: "newsecret1", current_password: "secret123" } }
    assert_redirected_to edit_user_url(@user)
    assert @user.reload.authenticate("newsecret1")
  end

  test "changing the email needs the current password, the name doesn't" do
    patch user_url(@user), params: { user: { email: "new@ex.com", name: "renamed" } }
    assert_response :unprocessable_entity
    assert_equal "tankowner@ex.com", @user.reload.email

    patch user_url(@user), params: { user: { name: "renamed" } }
    assert_equal "renamed", @user.reload.name
  end

  test "a blank new password leaves the password alone" do
    patch user_url(@user), params: { user: { password: "", theme: "light" } }
    assert_redirected_to edit_user_url(@user)
    assert @user.reload.authenticate("secret123")
  end

  test "can't edit someone else" do
    other = User.create!(name: "otheruser", email: "other@ex.com", password: "secret123")
    patch user_url(other), params: { user: { theme: "dark" } }
    assert_equal "system", other.reload.theme
  end

  test "guests are sent to log in" do
    delete logout_url
    get edit_user_url(@user)
    assert_redirected_to login_url
  end
end
