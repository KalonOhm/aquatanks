class SpeciesController < ApplicationController
  before_action :set_species, only: %i[ show edit update destroy ]

  # GET /species or /species.json
  # Optional filters: ?q= (search any name), ?category=, ?water=, plus ?page= / ?per_page=
  def index
    # No water param at all means "use my default"; a blank one means the user picked "Any"
    @water = params.key?(:water) ? params[:water] : helpers.preferences.default_water

    sort = helpers.preferences.scientific_names_first ? Arel.sql("COALESCE(taxonomic_name, common_name)") : :common_name
    species = Species.search(params[:q]).order(sort)
    species = species.where(category: params[:category]) if params[:category].in?(Species::CATEGORIES)
    species = species.where(preferred_water: @water) if @water.in?(Species::WATER_TYPES)
    @species_list = paginate(species)
  end

  # GET /species/1 or /species/1.json
  def show
  end

  # GET /species/new
  def new
    @species = Species.new
  end

  # GET /search_species?term=&water=&strict=
  # Used by the tank page's search-as-you-type. Species suited to `water`
  # (a Species::WATER_TYPES value, usually the tank's) come first; with
  # strict=1 (the "strict add search" preference) they're the only ones.
  def search
    return render json: [] if params[:term].to_s.strip.length < 2

    water = params[:water].presence_in(Species::WATER_TYPES)
    @species_list = Species.search(params[:term])
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
    @species = Species.new(species_params)

    respond_to do |format|
      if @species.save
        format.html { redirect_to species_url(@species), notice: "Species was successfully created." }
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
        format.html { redirect_to species_url(@species), notice: "Species was successfully updated." }
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
      format.html { redirect_to species_index_url, notice: "Species was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_species
      @species = Species.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def species_params
      params.require(:species).permit(:common_name, :alias_list, :taxonomic_name, :category, :image_url, :size, :other_remarks, :preferred_water)
    end
end
