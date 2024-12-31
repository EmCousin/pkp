Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'registrations'
  }

  authenticated :user do
    root to: "dashboard#show", as: :authenticated
  end

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :errors, only: [] do
    collection do
      get :offline
    end
  end

  scope module: :pwa do
    resource :service_worker, only: :show
    resource :manifest, only: :show
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :pdfs, only: :index do
    collection do
      post :notify
    end
  end

  namespace :admin do
    resources :courses do
      resources :attendance_sheets, only: [:create]
    end
    resources :attendance_sheets, only: [:show, :update]
    resources :categories, only: [:new, :create, :edit, :update, :destroy]
    resources :members
    resources :subscriptions do
      member do
        delete :unlink_course
      end
      resource :invoice, only: [:show, :create, :edit, :update]
      resources :credit_notes, only: [:new, :create]
    end
  end

  resources :admin, only: [:index]

  resources :contacts, only: [] do
    scope module: :contacts do
      resource :confirmation, only: %i[show destroy]
    end
  end

  namespace :dashboard do
    resources :members, only: [:new, :create, :edit, :update]
    resources :subscriptions, only: [:new, :create] do
      resource :signed_form, only: [:edit, :update]
      resource :medical_certificate, only: [:edit, :update]
      resource :payment, only: [:new, :create]
    end
    resource :vacation, only: [:show]
    resource :capacity, only: [:show]
    resource :alumni_access, only: %i[new create]
  end

  resource :dashboard, controller: :dashboard, only: [:show]

  resources :legal_mentions, only: %i[index]

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  namespace :coach do
    resources :courses, only: [:index] do
      resources :attendance_sheets, only: [:create]
    end
    resources :attendance_sheets, only: [:show, :update]
  end
end
