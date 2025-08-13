Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    registrations: 'registrations'
  }

  direct :next_completion_step do |subscription|
    next edit_dashboard_subscription_terms_path(subscription) unless subscription.terms_accepted_at?
    next edit_dashboard_subscription_medical_certificate_path(subscription) unless subscription.doctor_certified_at?
    next new_dashboard_subscription_payment_path(subscription) unless subscription.paid? || subscription.payment_proof.attached?

    dashboard_path
  end

  authenticated :user do
    root to: "dashboard#show", as: :authenticated
  end


  authenticate :user, ->(user) { user.admin? } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgHero::Engine, at: "/pghero"
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

  concern :courses_manageable do
    resources :courses do
      resources :attendance_sheets, only: [:create]
    end
    resources :attendance_sheets, only: [:show] do
      resources :attendance_records, only: [:update]
    end
  end

  namespace :admin do
    concerns :courses_manageable

    resources :categories, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :members do
      resource :level, only: [:update]
    end

    resources :camps do
      resources :subscriptions, only: [:create, :destroy], controller: 'camps/subscriptions'
    end

    resources :subscriptions do
      resource :payment, only: [:create, :destroy]
      resource :status, only: [:update]
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
    resources :subscriptions, only: [:show, :new, :create] do
      resource :term, as: :terms, only: [:edit, :update]
      resource :medical_certificate, only: [:edit, :update]
      resource :payment_proof, only: [:edit, :update]
      resource :payment, only: [:show, :new, :create]
    end
    resources :camps, only: [:index, :show] do
      resources :subscriptions, only: [:create, :destroy], controller: 'camps/subscriptions' do
        resource :payment_proof, only: [:edit, :update], module: :camps
      end
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
    concerns :courses_manageable
  end
end
