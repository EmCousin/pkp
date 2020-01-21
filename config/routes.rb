Rails.application.routes.draw do
  mount LetsEncrypt::Engine => '/.well-known'

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
    resources :subscriptions do
      member do
        delete :unlink_course
      end
    end
  end

  resources :admin, only: [:index]

  namespace :dashboard do
    resources :subscriptions, only: [:new, :create]
  end

  resources :dashboard, only: [:index]
  root "dashboard#index"
end
