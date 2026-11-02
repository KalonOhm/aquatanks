require "application_system_test_case"

# The theme is applied by a script in the layout's <head>. Turbo keeps <html>
# between pages, so these check the theme still switches (and the flash
# message survives) when logging in or saving a new theme.
class ThemeTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "tankowner", email: "owner@ex.com", password: "secret123", theme: "dark")
  end

  test "logging in switches to the user's theme and keeps the message" do
    visit login_url
    assert_no_selector "html.dark" # guests follow the device, light in headless Chrome

    fill_in "Email", with: @user.email
    fill_in "Password", with: "secret123"
    click_button "Login"
    assert_text "Login successful"
    assert_selector "html.dark"
  end

  test "saving a new theme applies it straight away" do
    visit login_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "secret123"
    click_button "Login"
    assert_text "Login successful"

    visit edit_user_url(@user)
    select "Light", from: "Theme"
    click_on "Save"
    assert_text "Profile saved."
    assert_no_selector "html.dark"
  end
end
