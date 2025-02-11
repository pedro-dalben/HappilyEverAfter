class Admin::UsersController < AdminController
  skip_before_action :authenticate_user!, only: [ :new, :create ], if: -> { User.count.zero? }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:notice] = "User created successfully."
      redirect_to root_path
    else
      flash.now[:alert] = "There was a problem creating the user."
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
