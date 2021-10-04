module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler
        module SubscriptionApiHandler
          def subscribe(subscription_plan)
            raise_invalid_object_error(subscription_plan, Spree::SubscriptionPlan)
            token = subscription_plan.card_token
            spree_card = subscription_plan.user.create_stripe_card(token)
            customer = subscription_plan.user.find_or_create_stripe_customer(token)
            begin
              stripe_subscription = Stripe::Subscription.create(stripe_subscription_params(customer.id, subscription_plan))
              subscription_plan.stripe_subscription_id = stripe_subscription.id
              subscription_plan.user.promote_distributor!
            rescue Stripe::InvalidRequestError, Stripe::AuthenticationError, Stripe::StripeError
              false
            end
          end

          def unsubscribe(subscription_plan)
            raise_invalid_object_error(subscription_plan, Spree::SubscriptionPlan)

            begin
              stripe_subscription = Stripe::Subscription.retrieve(subscription_plan.stripe_subscription_id)
              stripe_subscription.delete
              subscription_plan.user.inactivate_distributor!
            rescue Stripe::InvalidRequestError, Stripe::AuthenticationError, Stripe::StripeError
              false
            end
          end

          private

            def stripe_subscription_params(customer_id, subscription_plan)
              {
                customer: customer_id,
                items: [
                  {
                    plan: subscription_plan.plan.api_plan_id
                  },
                ]
              }
            end
        end
      end
    end
  end
end
