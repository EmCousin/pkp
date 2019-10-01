Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :pdfs, only: :index do
    collection do
      post :notify
    end
  end

  namespace :admin do
    resources :courses
    resources :users
    resources :subscriptions
  end

  resources :admin, only: [:index, :show, :create]
  root "admin#index"
end
