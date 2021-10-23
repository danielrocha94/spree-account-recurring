require 'base64'
class Spree::App::Api::V1::SubscriptionPlansController < App::Api::V1::ApplicationController
  before_action :find_active_plan, only: [:new, :create]
  before_action :find_plan, only: [:show, :destroy]
  before_action :find_subscription, only: [:destroy]
  before_action :authenticate_subscription, only: [:new, :create]

  def create
      subscription_plans_params = {
        user_id: spree_current_user.id,
      }

      subscription_plans_params[:card_token] = params[:subscription][:card_token] if params[:subscription].present?

      @subscription = @plan.subscription_plans.build(subscription_plans_params)
      
      if @subscription.save_and_manage_api
        render :json => {
          message: "Gracias por tu subscripción.",
          user_subscriptions: find_user_active_subscriptions
        }
      else
        render :json => {
          message: "No se ha podido realizar la suscripción, por favor verifica los datos.",
          user_subscriptions: find_user_active_subscriptions,
          status: :bad_request
        }, status: :bad_request
      end
  end

  def destroy
    if @subscription.save_and_manage_api(unsubscribed_at: Time.current)
      render :json => {
        message: "La subscripción ha sido cancelada.",
        user_subscriptions: find_user_active_subscriptions
      }
    else
      render :json => {
        error: {
          message: @subscription.errors.full_messages.join(",")
        },
        status: :bad_request
      }, status: :bad_request
    end
  end

  private

  def find_user_active_subscriptions
    spree_current_user.subscription_plans.undeleted.all.to_a
  end

  def find_active_plan
    unless @plan = Spree::Plan.active.where(id: params[:plan_id]).first
      return render :json => {
        error: {
          message: "El Plan no pudo ser encontrado."
        },
        status: :not_found
      }, status: :not_found
    end
  end

  def find_plan
    unless @plan = Spree::Plan.where(id: params[:plan_id]).first
      return render :json => {
        error: {
          message: "El Plan no pudo ser encontrado."
        },
        status: :not_found
      }, status: :not_found
    end
  end

  def authenticate_subscription
    if subscription = spree_current_user.subscription_plans.undeleted.first
      return render :json => {
        status: :conflict, #409
        error: {
          message: "Ya te has registrado anteriormente."
        },
        plan: @plan,
        subscription: subscription
      }, status: :conflict
    end
  end
end

def find_subscription
  unless @subscription = @plan.subscription_plans.undeleted.where(id: params[:id]).first
    render :json => {
      error: {
        message: "Subscription not found."
      },
      status: :not_found
    }, status: :not_found
  end
end


