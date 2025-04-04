module Api
  class ApplicationController < ActionController::Base
    skip_before_action :verify_authenticity_token

    # Remove o layout padrão da aplicação
    layout false

    protected

    def render_error(message, status = :unprocessable_entity)
      render json: { error: message }, status: status
    end
  end
end
