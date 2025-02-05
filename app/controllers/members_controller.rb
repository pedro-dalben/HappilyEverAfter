class MembersController < ApplicationController
  layout "admin"

  before_action :set_family
  before_action :set_member, only: [ :edit, :update, :destroy ]

  def index
    @members = @family.members
  end

  def new
    @member = @family.members.build
  end

  def create
    @member = @family.members.build(member_params)
    if @member.save
      redirect_to family_members_path(@family), notice: "Member created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @member.update(member_params)
      redirect_to family_members_path(@family), notice: "Member updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @member.destroy

    respond_to do |format|
      format.html { head :no_content }
      format.json { render json: { message: "member deleted successfully." }, status: :ok }
    end
  end

  private

  def set_family
    @family = Family.find(params[:family_id])
  end

  def set_member
    @member = @family.members.find(params[:id])
  end

  def member_params
    params.require(:member).permit(:name, :age, :gender)
  end
end
