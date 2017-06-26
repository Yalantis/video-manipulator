Rails.application.routes.draw do
  resources :videos
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'videos#index'
end
