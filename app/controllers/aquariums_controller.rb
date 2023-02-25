class AquariumsController < ApplicationController
  before_action :set_aquarium, only: %i[ show edit update destroy ]

  # GET /aquariums or /aquariums.json
  def index
    @aquariums = Aquarium.all
  end

  # GET /aquariums/1 or /aquariums/1.json
  def show
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
    @aquarium = Aquarium.new(aquarium_params)

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_aquarium
      @aquarium = Aquarium.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def aquarium_params
      params.require(:aquarium).permit(:size, :water_type, :filter, :plants, :user_id)
    end
end