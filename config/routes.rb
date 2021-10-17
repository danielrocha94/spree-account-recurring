Rails.application.routes.draw do 
  Spree::Core::Engine.routes.draw do
    namespace :admin do
      resources :recurrings, except: :show do
        resources :plans, except: :show
      end

      resources :subscription_plans, only: :index
      resources :subscription_events, only: :index
    end

    resources :recurring_hooks, only: :none do
      post :handler, on: :collection
    end

    resources :plans, only: :index, controller: :plans do
      resources :subscription_plans, only: [:show, :create, :destroy, :new]
    end

  end

  scope "(:locale)", locale: /en|es/ do
    namespace :app do
      namespace :api, defaults: {format: :json} do
        namespace :v1 do
          get 'plans/get_subscribed_plans' => 'plans#get_subscribed_plans'
          resources :plans, only: :index, controller: :plans do
            resources :subscription_plans, only: [:show, :create, :destroy]
          end
        end
      end
    end
  end
end

