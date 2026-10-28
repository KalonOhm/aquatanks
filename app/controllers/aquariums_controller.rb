class AquariumsController < ApplicationController
  before_action :require_user, only: %i[ new create ]
  before_action :set_aquarium, only: %i[ show edit update destroy add_fish remove_fish ]
  before_action :require_owner, only: %i[ edit update destroy add_fish remove_fish ]

  # GET /aquariums or /aquariums.json
  def index
    @aquariums = Aquarium.all
  end

  # GET /aquariums/1 or /aquariums/1.json
  def show
    # @aquarium = Aquarium.find(params[:id])
  end

  # GET /aquariums/new
  def new
    @aquarium = Aquarium.new
  end

  # GET /aquariums/1/edit
  def edit
  end

  # POST /aquariums or /aquariums.json
  def create
    @aquarium = helpers.current_user.aquariums.new(aquarium_params)

    respond_to do |format|
      if @aquarium.save
        format.html { redirect_to aquarium_url(@aquarium), notice: "Aquarium was successfully created." }
        format.json { render :show, status: :created, location: @aquarium }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @aquarium.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /aquariums/1 or /aquariums/1.json
  def update
    respond_to do |format|
      if @aquarium.update(aquarium_params)
        format.html { redirect_to aquarium_url(@aquarium), notice: "Aquarium was successfully updated." }
        format.json { render :show, status: :ok, location: @aquarium }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @aquarium.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /aquariums/1 or /aquariums/1.json
  def destroy
    @aquarium.destroy

    respond_to do |format|
      format.html { redirect_to aquariums_url, notice: "Aquarium was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def add_fish
    # @aquarium = Aquarium.find(params[:id])
    @fish = Fish.find(params[:fish_id]) #TODO: figure out how to search fishes field 
    @count = params[:count].to_i
    aquarium_fish = @aquarium.aquariums_fishes.create(fish: @fish, count: @count)
    if aquarium_fish.persisted?
      redirect_to @aquarium, notice: "Added #{@fish.common_name}."
    else
      redirect_to @aquarium, notice: aquarium_fish.errors.full_messages.to_sentence
    end
  end

  def remove_fish
    aquarium_fish = @aquarium.aquariums_fishes.find(params[:aquarium_fish_id])
    aquarium_fish.destroy
    redirect_to @aquarium, notice: "Removed one #{aquarium_fish.fish.common_name}."  
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_aquarium
      @aquarium = Aquarium.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def aquarium_params
      params.require(:aquarium).permit(:size, :water_type, :filter, :plants, :substrate)
      # removed :user_id from params list
    end

    def require_owner
      unless @aquarium.user == helpers.current_user
        redirect_to @aquarium, alert: "Only this tank's owner can perform this action."
      end
    end
end
