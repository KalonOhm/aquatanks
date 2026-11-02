require "test_helper"

class PagingTest < ActionDispatch::IntegrationTest
  setup do
    # 30 species named "Zebra 00".."Zebra 29", plus the 3 fixtures
    30.times { |i| Species.create!(common_name: format("Zebra %02d", i)) }
  end

  def names_on_page
    css_select("#species h5").map(&:text)
  end

  test "guests get 25 per page" do
    get species_index_url
    assert_equal 25, names_on_page.size
    assert_select "nav[aria-label=Pages]", text: /Showing 1–25 of 33/
  end

  test "page and per_page params pick the slice" do
    get species_index_url, params: { q: "zebra", per_page: 10, page: 2 }
    assert_equal (10..19).map { |i| "Zebra #{i}" }, names_on_page
    # links keep the search and page size
    assert_select "a[rel=next][href*='q=zebra'][href*='per_page=10'][href*='page=3']"
  end

  test "a page past the end shows the last page" do
    get species_index_url, params: { q: "zebra", per_page: 10, page: 99 }
    assert_equal (20..29).map { |i| "Zebra #{i}" }, names_on_page
  end

  test "an unsupported per_page falls back to the preference" do
    sign_in_new_user(per_page: 10)
    get species_index_url, params: { per_page: 7 }
    assert_equal 10, names_on_page.size
  end

  test "page window shows gaps" do
    page = Pagination::Page.new(number: 5, per_page: 10, total_count: 300, total_pages: 30)
    assert_equal [1, nil, 3, 4, 5, 6, 7, nil, 30], page.window
    assert_equal [41, 50], [page.first_item, page.last_item]
  end
end
