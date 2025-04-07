require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }, skip: [ :registrations ]

  # Área Administrativa Unificada
  namespace :admin do
    # Dashboard administrativo
    root to: "dashboard#index"

    # Usuários admin
    resources :users, only: [ :new, :create, :index ]

    # Gerenciamento de presentes no admin
    resources :gifts, only: [ :index, :show, :edit, :update ] do
      member do
        get :show_order
        patch :update_status
        get :show
      end
    end

    # Gerenciamento de famílias no admin
    resources :families

    # Relatórios e estatísticas
    get "reports", to: "reports#index"

    # Montagem do Sidekiq dentro do namespace admin
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => "/sidekiq"
    end
  end

  # API endpoints
  namespace :api do
    post "webhooks/asaas", to: "webhooks#asaas"
  end

  root "home#index"

  resources :whatsapp_messages, only: [ :new, :create, :index, :show ]

  resources :families do
    resources :members, except: [ :show ]
  end
  resources :gift_items do
    member do
      post :toggle_status
    end
  end

  get "rsvp", to: "rsvp#index"
  post "rsvp/validate_token", to: "rsvp#validate_token"
  get "rsvp/members", to: "rsvp#members"
  post "rsvp/confirm", to: "rsvp#confirm"
  get "rsvp/confirmation", to: "rsvp#confirmation"
  get "confirmar/:token", to: "rsvp#direct_access", as: :rsvp_direct

  resources :labels, only: [ :index ] do
    collection do
      get :generate
    end
  end

  # Gift Registry
  get "gift-registry", to: "gift_registry#index", as: :gift_registry
  get "gift-registry/authenticate", to: "gift_registry#authenticate", as: :gift_registry_authenticate
  post "gift-registry/verify-token", to: "gift_registry#verify_token", as: :gift_registry_verify_token
  post "gift-registry/add-to-cart/:id", to: "gift_registry#add_to_cart", as: :add_to_cart
  get "gift-registry/cart", to: "gift_registry#cart", as: :cart
  delete "gift-registry/cart/:id", to: "gift_registry#remove_from_cart", as: :remove_from_cart
  get "gift-registry/checkout", to: "gift_registry#checkout", as: :checkout
  post "gift-registry/process-payment", to: "gift_registry#process_payment", as: :process_payment
  post "gift-registry/payment-webhook", to: "gift_registry#payment_webhook", as: :payment_webhook
  get "gift-registry/order-status/:id", to: "gift_registry#order_status", as: :order_status
  post "gift-registry/buy-now/:id", to: "gift_registry#buy_now", as: :buy_now
  delete "gift-registry/cart", to: "gift_registry#empty_cart", as: :empty_cart
  get "gift-registry/thank-you/:id", to: "gift_registry#thank_you", as: :thank_you
  get "gift-registry/payment-transition/:id", to: "gift_registry#payment_transition", as: "payment_transition"
  get "gift-registry/family-purchases/:token", to: "gift_registry#family_purchases", as: :family_purchases

  # Removido e migrado para o namespace admin
  # resources :admin_gifts, only: [:index, :show] do
  #   patch :update_status, on: :member
  # end
end
