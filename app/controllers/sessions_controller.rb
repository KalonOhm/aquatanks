class SessionsController < ApplicationController 
  before_action :set_user?, except: [:destroy]

  #GET login page
  def new 
  end

  def create 
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id 
      flash[:notice] = "Login successful"
      redirect_to aquariums_path
    else
      flash[:notice] = "Login failed"
      render :new, status: unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil 
    flash[:notice] = "Logout successful"
    redirect_to login_path
  end
end
