module ApplicationHelper

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  # The signed-in user's settings, or the defaults for a guest (a new User's
  # column defaults), so callers never need to check for nil
  def preferences
    current_user || (@guest_preferences ||= User.new)
  end

end
