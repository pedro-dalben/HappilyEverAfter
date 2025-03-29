class Admin::DashboardController < AdminController
  def index
    # Estatísticas gerais para o dashboard
    @total_families = Family.count
    @total_gifts = GiftItem.count
    @recent_orders = Order.recent.limit(5)
  end
end
