require 'stripe'
require 'stripe_tester' if Rails.env.development? || Rails.env.test?

Stripe.api_version = "2018-02-28" 
Stripe.api_key = Spree::Recurring.last.preferred_secret_key
