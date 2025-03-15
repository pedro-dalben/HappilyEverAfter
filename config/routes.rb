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

  resources :labels, only: [:index] do
    collection do
      get :generate
    end
  end
end
