module ApplicationHelper
  def show_cart?
    # Apenas mostrar o carrinho nas páginas relacionadas à lista de presentes
    controller_name == 'gift_registry' &&
    !['authenticate', 'verify_token'].include?(action_name)
  end
end
