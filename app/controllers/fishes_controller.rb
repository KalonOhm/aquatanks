class FishesController < ApplicationController
  before_action :set_fish, only: %i[ show edit update destroy ]

  # GET /fish or /fish.json
  def index
    @fishes = Fish.all
  end

  # GET /fishes/1 or /fishes/1.json
  def show
  end

  # GET /fishes/new
  def new
    @fish = Fish.new
  end

  # GET /fishes/1/edit
  def edit
  end

  # POST /fishes or /fishes.json
  def create
    @fish = Fish.new(fish_params)

    respond_to do |format|
      if @fish.save
        format.html { redirect_to fish_url(@fish), notice: "Fish was successfully created." }
        format.json { render :show, status: :created, location: @fish }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fish.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fishes/1 or /fishes/1.json
  def update
    respond_to do |format|
      if @fish.update(fish_params)
        format.html { redirect_to fish_url(@fish), notice: "Fish was successfully updated." }
        format.json { render :show, status: :ok, location: @fish }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fish.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fishes/1 or /fishes/1.json
  def destroy
    @fish.destroy

    respond_to do |format|
      format.html { redirect_to fishes, notice: "Fish was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fish
      @fish = Fish.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def fish_params
      params.require(:fish).permit(:common_name, :taxonomic_name, :image_url, :size, :other_remarks, :preferred_water)
    end
end
