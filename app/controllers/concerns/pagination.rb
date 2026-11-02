# Hand-rolled paging: ?page= and ?per_page= (one of User::PER_PAGE_OPTIONS,
# otherwise the viewer's preference). Render shared/_pagination with the
# @page this sets.
module Pagination
  Page = Data.define(:number, :per_page, :total_count, :total_pages) do
    def first_item = total_count.zero? ? 0 : (number - 1) * per_page + 1
    def last_item = [number * per_page, total_count].min
    def first? = number == 1
    def last? = number == total_pages

    # Page numbers to link, with nil for a gap: [1, nil, 4, 5, 6, nil, 89]
    def window(around: 2)
      shown = [1, total_pages, *(number - around..number + around)].select { |n| n.between?(1, total_pages) }.uniq.sort
      shown.each_cons(2).flat_map { |a, b| b - a > 1 ? [a, nil] : [a] } + [shown.last]
    end
  end

  # This page's slice of the scope; sets @page
  def paginate(scope)
    per_page = params[:per_page].to_i.presence_in(User::PER_PAGE_OPTIONS) || helpers.preferences.per_page
    total_count = scope.count
    total_pages = [(total_count / per_page.to_f).ceil, 1].max
    number = params[:page].to_i.clamp(1, total_pages)

    @page = Page.new(number:, per_page:, total_count:, total_pages:)
    scope.limit(per_page).offset((number - 1) * per_page)
  end
end
