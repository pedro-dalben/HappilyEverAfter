class AdminController < ApplicationController
  before_action :authenticate_user!
  layout "admin"

  before_action :require_admin

  private

  def require_admin
    unless current_user && current_user.admin?
      flash[:alert] = "Você não tem permissão para acessar esta área."
      redirect_to root_path
    end
  end
end
