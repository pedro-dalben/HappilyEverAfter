require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }, skip: [ :registrations ]
  mount Sidekiq::Web => "/sidekiq"

  root "home#index"

  resources :whatsapp_messages, only: [ :new, :create, :index, :show ]

  resources :families do
    resources :members, except: [ :show ]
  end
  resources :gift_items

  namespace :admin do
    resources :users, only: [ :new, :create ]
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
end
