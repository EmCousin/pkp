Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :pdfs, only: :index do
    collection do
      post :notify
    end
  end
end
