class ApplicationController < ActionController::Base
  include Pagination

  # Streams one pre-sized variant of an uploaded picture (see HasPhoto). Photos
  # go through our own controllers so each action can check who may see them;
  # Active Storage's own routes, whose links work for anyone, are turned off
  # (config.active_storage.draw_routes in config/application.rb).
  # public: false keeps browsers from sharing it through caches (private tanks).
  def send_photo(attachment, variant, allowed_variants, public:)
    variant = variant.to_s.to_sym
    # attachment: a has_one_attached (blank when nothing is attached) or one Attachment record
    return head(:not_found) unless attachment.present? && allowed_variants.include?(variant)

    expires_in 1.hour, public: public
    return unless stale?(etag: [attachment.blob.checksum, variant], public: public)

    data = attachment.variant(variant).processed.download
    send_data data, type: Marcel::MimeType.for(StringIO.new(data)), disposition: :inline
  end

  def require_user
    #if user is only guest tries to access resticted page, redirect to login page
    if guest?
      flash[:notice] = "You must log in to access this page"
      redirect_to login_path
    end
  end  
  
  def is_signed_in?
    if !guest?
      flash[:notice] = "Already signed in"
      redirect_to aquariums_path
    end
  end

  def guest?
    !helpers.logged_in?
  end

    


end
