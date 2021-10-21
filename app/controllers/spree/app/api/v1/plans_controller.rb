require 'base64'
class Spree::App::Api::V1::PlansController < App::Api::V1::ApplicationController
  before_action :load_user_subscriptions

  def index
    plans = Spree::Plan.visible.order('id desc')
    render :json => {
      plans: plans,
      user_subscriptions: @user_subscriptions
    }
  end

  def get_subscribed_plans 
  end

  private

    def load_user_subscriptions
      if spree_current_user
        @user_subscriptions = spree_current_user.subscription_plans.undeleted.all.to_a
      else
        @user_subscriptions = []
      end
    end
end
