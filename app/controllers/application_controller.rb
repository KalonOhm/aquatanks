class ApplicationController < ActionController::Base
  def require_user
    #if user is only guest tries to access resticted page, redirect to login page
    if guest?
      flash[:notice] = "You must log in to access this page"
      redirect_to login_path
    end
  end  
  
  def set_user?
    if !guest?
      flash[:notice] = "Already signed in"
      redirect_to aquariums_path
    end
  end

  def guest?
    !helpers.logged_in?
  end

    


end
