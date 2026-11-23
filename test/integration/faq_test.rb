require "test_helper"

class FaqTest < ActionDispatch::IntegrationTest
  test "the FAQ says species come from Wikipedia and links the source lists" do
    get root_url
    assert_select "nav a[href='#{faq_path}']"

    get faq_url
    assert_response :success
    assert_match "correct it on Wikipedia", response.body
    assert_select "a[href^='https://en.wikipedia.org/wiki/List_of_']", 8
  end
end
