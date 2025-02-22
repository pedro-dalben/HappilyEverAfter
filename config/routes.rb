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
end
