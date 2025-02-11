Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }, skip: [ :registrations ]

  root "home#index"

  resources :families do
    resources :members, except: [ :show ]
  end
  resources :gift_items

  namespace :admin do
    resources :users, only: [ :new, :create ]
  end
end
