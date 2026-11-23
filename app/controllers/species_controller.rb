class SpeciesController < ApplicationController
  # Official species (from the Wikipedia scrape) are read-only here. Logged-in
  # users can add custom species and change or delete only their own.
  before_action :require_user, only: %i[ new create edit update destroy ]
  before_action :set_species, only: %i[ show edit update destroy ]
  before_action :require_visible, only: %i[ show ]
  before_action :require_editable, only: %i[ edit update destroy ]

  # GET /species or /species.json
  # Optional filters: ?q= (search any name), ?category=, ?water=, plus ?page= / ?per_page=
  def index
    # No water param at all means "use my default"; a blank one means the user picked "Any"
    @water = params.key?(:water) ? params[:water] : helpers.preferences.default_water

    sort = helpers.preferences.scientific_names_first ? Arel.sql("COALESCE(taxonomic_name, common_name)") : :common_name
    species = Species.available_to(helpers.current_user).search(params[:q]).order(sort)
    species = species.where(category: params[:category]) if params[:category].in?(Species::CATEGORIES)
    species = species.where(preferred_water: @water) if @water.in?(Species::WATER_TYPES)
    @species_list = paginate(species)
  end

  # GET /species/1 or /species/1.json
  def show
  end

  # GET /species/new — a custom species. ?aquarium_id= (from a tank's add box)
  # stocks one in that tank once it's saved.
  def new
    @species = Species.new(preferred_water: own_aquarium&.species_water)
  end

  # GET /search_species?term=&water=&strict=
  # Used by the tank page's search-as-you-type. Species suited to `water`
  # (a Species::WATER_TYPES value, usually the tank's) come first; with
  # strict=1 (the "strict add search" preference) they're the only ones.
  def search
    return render json: [] if params[:term].to_s.strip.length < 2

    water = params[:water].presence_in(Species::WATER_TYPES)
    @species_list = Species.available_to(helpers.current_user).search(params[:term])
    if water && params[:strict].present?
      @species_list = @species_list.where(preferred_water: water)
    elsif water
      # (in_order_of returns nothing at all when given an empty list, hence the if)
      @species_list = @species_list.in_order_of(:preferred_water, [water], filter: false)
    end
    @species_list = @species_list.order(:common_name).limit(25)
    render json: @species_list.map { |species|
      {
        id: species.id,
        text: helpers.species_name(species),
        other_name: helpers.species_other_name(species),
        kind: helpers.species_kind(species),
        suits_water: water.nil? || species.preferred_water == water,
      }
    }
  end

  # GET /species/1/edit
  def edit
  end

  # POST /species or /species.json
  def create
    @species = helpers.current_user.custom_species.new(species_params)

    respond_to do |format|
      if @species.save
        aquarium = own_aquarium
        aquarium&.aquarium_species&.create!(species: @species, count: 1)
        format.html do
          if aquarium
            redirect_to aquarium, notice: "Added your custom species #{@species.common_name.presence || @species.taxonomic_name}."
          else
            redirect_to species_url(@species), notice: "Custom species added."
          end
        end
        format.json { render :show, status: :created, location: @species }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @species.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /species/1 or /species/1.json
  def update
    respond_to do |format|
      if @species.update(species_params)
        format.html { redirect_to species_url(@species), notice: "Custom species updated." }
        format.json { render :show, status: :ok, location: @species }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @species.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /species/1 or /species/1.json
  def destroy
    @species.destroy

    respond_to do |format|
      format.html { redirect_to species_index_url, notice: "Custom species deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_species
      @species = Species.find(params[:id])
    end

    def require_visible
      redirect_to species_index_path, alert: "That species isn't available." unless @species.visible_to?(helpers.current_user)
    end

    def require_editable
      return if @species.editable_by?(helpers.current_user)

      message = @species.official? ? "Catalog species come from Wikipedia and can't be edited here (see the FAQ)." : "You can only change your own custom species."
      redirect_to species_url(@species), alert: message
    end

    # The tank named by ?aquarium_id= (or the form's hidden field), if it's the current user's
    def own_aquarium
      id = params[:aquarium_id].presence
      id && helpers.current_user&.aquariums&.find_by(id: id)
    end

    # Only allow a list of trusted parameters through.
    def species_params
      params.require(:species).permit(:common_name, :alias_list, :taxonomic_name, :category, :image_url, :size, :other_remarks, :preferred_water)
    end
end
