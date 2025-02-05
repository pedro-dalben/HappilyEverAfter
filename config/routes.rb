
Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  resources :families do
    resources :members, except: [ :show ]
  end

  resources :gift_items
end
