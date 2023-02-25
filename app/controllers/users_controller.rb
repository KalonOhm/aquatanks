class UsersController < ApplicationController
  before_action :set_user?, only: [:new, :create]

  # GET /users/new
    def new
      @user = User.new
    end

  

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    if @user.save
      flash[:notice] = "Successfully created profile"
      redirect_to root_path
    else 
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/1 or /users/1.json
    def show
      @user = User.find(params[:id])
    end

  private
    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :password)
    end
end
