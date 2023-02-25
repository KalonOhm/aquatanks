class ApplicationController < ActionController::Base
    def set_user?
      if guest?
        flash[:notice] = "Already signed in"
        redirect_to aquariums_path
      end
    end

    def guest?
      !helpers.logged_in?
    end



end
