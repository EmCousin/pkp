
class PissOffConstraint
  def matches?(request)
    return true if request.path.starts_with?('/wp')
    return true if request.path.starts_with?('/login')

    File.extname(request.url) == '.php'
  end

  def self.responder
    ->(_env) { [429, {}, ['
         / \
        |\_/|
        |---|
        |   |
        |   |
      _ |=-=| _
  _  / \|   |/ \
 / \|   |   |   ||\
|   |   |   |   | \>
|   |   |   |   |   \
| -   -   -   - |)   )
|                   /
 \                 /
  \               /
   \             /
    \           /
  ']] }
  end
end

Rails.application.routes.draw do
  namespace :webhook do
    resource :stripe, only: :create
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  match "*path", to: PissOffConstraint.responder, constraints: PissOffConstraint.new, via: :all

  get "up" => "rails/health#show", as: :rails_health_check

  get 'users/sign_in', to: 'auth/sessions#new', as: :new_user_session
  post 'users/sign_in', to: 'auth/sessions#create', as: :user_session
  delete 'users/sign_out', to: 'auth/sessions#destroy', as: :destroy_user_session

  get 'users/sign_up', to: 'auth/registrations#new', as: :new_user_registration
  post 'users', to: 'auth/registrations#create', as: :user_registration
  get 'users/edit', to: 'auth/registrations#edit', as: :edit_user_registration
  get 'users/delete', to: 'auth/registrations#confirm_destroy', as: :delete_user_registration
  patch 'users', to: 'auth/registrations#update'
  put 'users', to: 'auth/registrations#update'
  delete 'users', to: 'auth/registrations#destroy'

  get 'users/password/new', to: 'auth/passwords#new', as: :new_user_password
  get 'users/password/edit', to: 'auth/passwords#edit', as: :edit_user_password
  post 'users/password', to: 'auth/passwords#create', as: :user_password
  patch 'users/password', to: 'auth/passwords#update'
  put 'users/password', to: 'auth/passwords#update'

  get 'users/unlock/new', to: 'auth/unlocks#new', as: :new_user_unlock
  get 'users/unlock', to: 'auth/unlocks#show', as: :user_unlock
  post 'users/unlock', to: 'auth/unlocks#create'

  direct :next_completion_step do |subscription|
    next edit_dashboard_subscription_terms_path(subscription) unless subscription.terms_accepted_at?
    if subscription.medical_certificate_required?
      medical_certificate = Subscriptions::MedicalCertificate.new(subscription:)
      next edit_dashboard_subscription_medical_certificate_path(subscription) unless medical_certificate.valid?
    end
    next new_dashboard_subscription_payment_path(subscription) unless subscription.paid? || subscription.payment_proof.attached?

    dashboard_path
  end

  constraints Auth::AuthenticatedConstraint.new do
    root to: "dashboard#show", as: :authenticated
  end


  constraints Auth::AuthenticatedConstraint.new(&:admin?) do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgHero::Engine, at: "/pghero"
  end
  match '/jobs(/*path)', to: 'auth/protected_routes#show', via: :all
  match '/pghero(/*path)', to: 'auth/protected_routes#show', via: :all

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
    get '/', to: redirect('/admin/members')
    concerns :courses_manageable
    resource :platform, only: %i[edit update]

    resources :categories, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      post :renew_pricings, on: :collection
    end
    resources :members do
      resource :level, only: [:update]
    end

    resources :camps do
      resources :subscriptions, only: [:create, :destroy], controller: 'camps/subscriptions'
    end
    resources :discovery_sessions do
      resources :subscriptions, only: :update, controller: 'discovery_sessions/subscriptions'
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
    resources :members
    resources :subscriptions, only: [:show, :new, :create] do
      resource :term, as: :terms, only: [:edit, :update]
      resource :medical_certificate, only: [:edit, :update]
      resource :payment_proof, only: [:edit, :update]
      resource :payment, only: [:show, :new]
    end
    resources :camps, only: [:index, :show] do
      resources :subscriptions, only: [:create, :destroy], controller: 'camps/subscriptions' do
        resource :payment_proof, only: [:edit, :update], module: :camps
      end
      resources :registrations, only: [:create, :destroy], controller: 'camps/registrations'
    end
    resources :discovery_sessions, only: %i[index show create] do
      resources :subscriptions, only: %i[create destroy], controller: 'discovery_sessions/subscriptions'
    end
    resource :vacation, only: [:show]
    resource :capacity, only: [:show]
    resource :alumni_access, only: %i[new create]
  end

  resource :dashboard, controller: :dashboard, only: [:show]

  resources :legal_mentions, only: %i[index]

  root to: 'auth/sessions#new'

  namespace :coach do
    concerns :courses_manageable
    resources :discovery_sessions, only: %i[index show] do
      resources :subscriptions, only: :update, controller: 'discovery_sessions/subscriptions'
    end
  end
end
