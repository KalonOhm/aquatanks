class AquariaController < ApplicationController
  before_action :set_aquarium, only: %i[ show edit update destroy ]

  # GET /aquaria or /aquaria.json
  def index
    @aquaria = Aquarium.all
  end

  # GET /aquaria/1 or /aquaria/1.json
  def show
  end

  # GET /aquaria/new
  def new
    @aquarium = Aquarium.new
  end

  # GET /aquaria/1/edit
  def edit
  end

  # POST /aquaria or /aquaria.json
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

  # PATCH/PUT /aquaria/1 or /aquaria/1.json
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

  # DELETE /aquaria/1 or /aquaria/1.json
  def destroy
    @aquarium.destroy

    respond_to do |format|
      format.html { redirect_to aquaria_url, notice: "Aquarium was successfully destroyed." }
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
