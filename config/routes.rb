Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'registrations'
  }

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
    resources :members
    resources :subscriptions do
      member do
        delete :unlink_course
        put :confirm
        put :archive
      end
      resource :invoice, only: [:show, :create, :edit, :update]
      resources :credit_notes, only: [:new, :create]
    end
  end

  resources :admin, only: [:index]

  namespace :dashboard do
    resources :members, only: [:new, :create]
    resources :subscriptions, only: [:new, :create] do
      resource :medical_certificate, only: [:edit, :update]
      resource :signed_form, only: [:edit, :update]
      resource :payment, only: [:new, :create]
    end
    resources :vacations, only: [:index]
    resources :capacities, only: [:index]
  end

  resources :dashboard, only: [:index]

  root "dashboard#index"
end
