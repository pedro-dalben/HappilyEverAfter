class RsvpController < ApplicationController
  def index
    # Página inicial para inserir o código
  end

  def validate_token
    @family = Family.find_by(token: params[:token].upcase)

    if @family
      session[:family_id] = @family.id
      redirect_to rsvp_members_path
    else
      flash.now[:error] = "Não encontramos sua família. Entre em contato via WhatsApp para obter ajuda."
      render :index
    end
  end

  def members
    @family = Family.find(session[:family_id])
    @members = @family.members
  rescue ActiveRecord::RecordNotFound
    redirect_to rsvp_path, alert: "Por favor, insira seu código de confirmação primeiro."
  end

  def confirm
    @family = Family.find(session[:family_id])

    if params[:member_ids].present?
      # Atualiza os membros selecionados para confirmados
      Member.where(id: params[:member_ids]).update_all(confirmed: true)

      # Atualiza os membros não selecionados para não confirmados
      Member.where(family_id: @family.id).where.not(id: params[:member_ids]).update_all(confirmed: false)

      # Marca a família como confirmada
      @family.update(confirmed: true)

      redirect_to rsvp_confirmation_path
    else
      flash.now[:alert] = "Por favor, selecione pelo menos um membro para confirmar."
      @members = @family.members
      render :members
    end
  end

  def confirmation
    @family = Family.find(session[:family_id])
    @confirmed_members = @family.members.where(confirmed: true)
    @unconfirmed_members = @family.members.where(confirmed: false)
  rescue ActiveRecord::RecordNotFound
    redirect_to rsvp_path, alert: "Por favor, insira seu código de confirmação primeiro."
  end

  def direct_access
    @family = Family.find_by(token: params[:token].upcase)

    if @family
      session[:family_id] = @family.id
      redirect_to rsvp_members_path
    else
      flash[:error] = "Código de família inválido. Entre em contato via WhatsApp para obter ajuda."
      redirect_to rsvp_path
    end
  end
end
