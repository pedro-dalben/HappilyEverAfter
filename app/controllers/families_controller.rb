class FamiliesController < AdminController
  before_action :set_family, only: [ :show, :edit, :update, :destroy ]

  def index
    @families = Family.all
  end

  def show
  end

  def new
    @family = Family.new
  end

  def create
    @family = Family.new(family_params)
    if @family.save
      redirect_to families_path, notice: "Family created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @family.update(family_params)
      redirect_to families_path, notice: "Family updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @family.destroy

    respond_to do |format|
      format.html { head :no_content }
      format.json { render json: { message: "Family deleted successfully." }, status: :ok }
    end
  end

  private

  def set_family
    @family = Family.find(params[:id])
  end

  def family_params
    params.require(:family).permit(:name, :phone, :token)
  end
end
