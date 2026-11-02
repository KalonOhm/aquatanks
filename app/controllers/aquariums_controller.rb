class AquariumsController < ApplicationController
  before_action :require_user, only: %i[ new create ]
  before_action :set_aquarium, only: %i[ show edit update destroy add_species remove_species ]
  before_action :require_visible, only: %i[ show edit update destroy add_species remove_species ]
  before_action :require_owner, only: %i[ edit update destroy add_species remove_species ]

  # GET /aquariums or /aquariums.json
  # Public tanks, plus the viewer's own private ones
  def index
    @aquariums = paginate(Aquarium.visible_to(helpers.current_user).includes(:user).order(created_at: :desc))
  end

  # GET /aquariums/1 or /aquariums/1.json
  def show
    # [[category, [stocked entries sorted by name]], ...] in Species::CATEGORIES order
    @stock_by_category = @aquarium.aquarium_species.includes(:species)
      .sort_by { |entry| helpers.species_name(entry.species).downcase }
      .group_by { |entry| entry.species.category }
      .sort_by { |category, _| Species::CATEGORIES.index(category) }
  end

  # GET /aquariums/new
  # Starts from the user's preferences: default water type and privacy
  def new
    @aquarium = Aquarium.new(
      water_type: Aquarium::WATER_TYPES.key(helpers.preferences.default_water),
      public: helpers.preferences.default_tank_public,
    )
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

  # Adds params[:count] of a species (the add form), or 1 when no count is sent (the + button).
  # If that species is already in the tank, its existing entry's count goes up instead of
  # creating a duplicate entry.
  def add_species
    @species = Species.find(params[:species_id]) #TODO: figure out how to search species field
    count = (params[:count] || 1).to_i
    if count < 1
      return redirect_to @aquarium, alert: "You can only add 1 or more."
    end

    aquarium_species = @aquarium.aquarium_species.find_or_initialize_by(species: @species)
    aquarium_species.count = aquarium_species.count.to_i + count

    if aquarium_species.save
      redirect_to @aquarium, notice: "Added #{count} #{@species.common_name}."
    else
      redirect_to @aquarium, alert: aquarium_species.errors.full_messages.to_sentence
    end
  end

  # Removes one, or deletes the whole entry when params[:all] is set.
  # Removing one stops at 0 and keeps the entry, so the tank remembers what to restock.
  def remove_species
    aquarium_species = @aquarium.aquarium_species.find(params[:aquarium_species_id])
    name = aquarium_species.species.common_name

    if params[:all].present?
      aquarium_species.destroy
      redirect_to @aquarium, notice: "Removed #{name} from this tank."
    elsif aquarium_species.count > 0
      aquarium_species.decrement!(:count)
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
    # The form takes the volume in the user's units; it's stored in gallons.
    def aquarium_params
      permitted = params.require(:aquarium).permit(:size, :water_type, :filter, :plants, :substrate, :public)
      permitted[:size] = Units.to_gallons(permitted[:size], helpers.preferences.units) if permitted.key?(:size)
      permitted
    end

    def require_visible
      unless @aquarium.visible_to?(helpers.current_user)
        redirect_to aquariums_path, alert: "That tank is private."
      end
    end

    def require_owner
      unless @aquarium.user == helpers.current_user
        redirect_to @aquarium, alert: "Only this tank's owner can perform this action."
      end
    end
end
