module Api
  class WebhooksController < Api::ApplicationController
    def asaas
      # Repassar a requisição para o método payment_webhook do GiftRegistryController
      gift_registry_controller = GiftRegistryController.new
      gift_registry_controller.request = request
      gift_registry_controller.response = response

      return gift_registry_controller.payment_webhook
    end
  end
end
