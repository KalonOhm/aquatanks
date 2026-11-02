class UsersController < ApplicationController
  before_action :is_signed_in?, only: [:new, :create]
  before_action :require_user, only: [:edit, :update]
  before_action :set_self, only: [:edit, :update]

  # Changing these needs the current password
  SENSITIVE_FIELDS = %w[email password].freeze

  # GET /users/new
    def new
      @user = User.new
    end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      flash[:notice] = "Successfully created profile"

      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/1 or /users/1.json
  # A user's tanks; other people only see the public ones
    def show
      @user = User.find(params[:id])
      @user_aquariums = paginate(@user.aquariums.visible_to(helpers.current_user).includes(:user).order(created_at: :desc))
    end

  # GET /users/1/edit — the profile page: account details and preferences
  def edit
  end

  # PATCH /users/1
  def update
    changes = profile_params
    changes = changes.except("password") if changes["password"].blank?

    changing_sensitive = changes.key?("password") || (changes.key?("email") && changes["email"] != @user.email)
    if changing_sensitive && !@user.authenticate(params.dig(:user, :current_password).to_s)
      @user.assign_attributes(changes.except(*SENSITIVE_FIELDS))
      @user.errors.add(:current_password, "is needed to change your email or password")
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(changes)
      redirect_to edit_user_path(@user), notice: "Profile saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :password)
    end

    def profile_params
      params.require(:user).permit(:name, :email, :password, :per_page, :units, :theme, :default_water,
        :scientific_names_first, :strict_add_search, :default_tank_public)
    end

    # You can only edit your own profile
    def set_self
      @user = helpers.current_user
      redirect_to edit_user_path(@user), alert: "You can only edit your own profile." unless params[:id].to_i == @user.id
    end
end
