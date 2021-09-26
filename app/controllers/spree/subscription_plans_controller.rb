module Spree
  class SubscriptionPlansController < StoreController
    prepend_before_action :load_object
    before_action :find_active_plan, only: [:new, :create]
    before_action :find_plan, only: [:show, :destroy]
    before_action :find_subscription, only: [:show, :destroy]
    before_action :authenticate_subscription, only: [:new, :create]

    def new
      @subscription = @plan.subscription_plans.build
    end

    def create
      @subscription = @plan.subscription_plans.build(subscription_params.merge(user_id: spree_current_user.id))
      if @subscription.save_and_manage_api
        redirect_to plan_subscription_plan_url(@plan, @subscription), notice: "Thank you for subscribing!"
      else
        render :new
      end
    end

    def destroy
      if @subscription.save_and_manage_api(unsubscribed_at: Time.current)
        redirect_to plans_path, notice: "Subscription has been cancelled."
      else
        flash.now[:error] = @subscription.errors.full_messages.join(",")
        render :show
      end
    end

    private

    def find_active_plan
      unless @plan = Spree::Plan.active.where(id: params[:plan_id]).first
        flash[:error] = "Plan not found."
        redirect_to plans_url
      end
    end

    def find_plan
      unless @plan = Spree::Plan.where(id: params[:plan_id]).first
        flash[:error] = "Plan not found."
        redirect_to plans_url
      end
    end

    def find_subscription
      unless @subscription = @plan.subscription_plans.undeleted.where(id: params[:id]).first
        flash[:error] = "Subscription not found."
        redirect_to root_url
      end
    end

    def subscription_params
      params.require(:subscription).permit(:email, :card_token)
    end

    def load_object
      @user ||= spree_current_user
    end

    def authenticate_subscription
      if subscription = spree_current_user.subscription_plans.undeleted.first
        flash[:alert] = "You have already subscribed."
        redirect_to plan_subscription_url(@plan, subscription)
      end
    end
  end
end
