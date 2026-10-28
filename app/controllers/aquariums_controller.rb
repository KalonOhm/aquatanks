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

  # Adds params[:count] fish (the add form), or 1 when no count is sent (the +1 button).
  # If that fish is already in the tank, its existing entry's count goes up instead of
  # creating a duplicate entry.
  def add_fish
    @fish = Fish.find(params[:fish_id]) #TODO: figure out how to search fishes field
    count = (params[:count] || 1).to_i
    if count < 1
      return redirect_to @aquarium, alert: "You can only add 1 or more fish."
    end

    aquarium_fish = @aquarium.aquariums_fishes.find_or_initialize_by(fish: @fish)
    aquarium_fish.count = aquarium_fish.count.to_i + count

    if aquarium_fish.save
      redirect_to @aquarium, notice: "Added #{count} #{@fish.common_name}."
    else
      redirect_to @aquarium, alert: aquarium_fish.errors.full_messages.to_sentence
    end
  end

  # Removes one fish, or deletes the whole entry when params[:all] is set.
  # Removing one stops at 0 and keeps the entry, so the tank remembers what to restock.
  def remove_fish
    aquarium_fish = @aquarium.aquariums_fishes.find(params[:aquarium_fish_id])
    name = aquarium_fish.fish.common_name

    if params[:all].present?
      aquarium_fish.destroy
      redirect_to @aquarium, notice: "Removed #{name} from this tank."
    elsif aquarium_fish.count > 0
      aquarium_fish.decrement!(:count)
      redirect_to @aquarium, notice: "Removed one #{name}."
    else
      redirect_to @aquarium, alert: "There are no #{name} left to remove."
    end
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
