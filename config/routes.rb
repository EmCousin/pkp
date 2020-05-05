Rails.application.routes.draw do
  devise_for :users

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
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
        put :confirm
        put :archive
      end
    end
  end

  resources :admin, only: [:index]

  namespace :dashboard do
    resources :subscriptions, only: [:new, :create] do
      resource :medical_certificate, only: [:edit, :update]
      resource :signed_form, only: [:edit, :update]
      resource :payment, only: [:new, :create]
    end
  end

  resources :dashboard, only: [:index]
  root "dashboard#index"
end
