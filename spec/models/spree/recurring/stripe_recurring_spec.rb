require 'spec_helper'

describe Spree::Recurring::StripeRecurring do
  let(:stripe_recurring) { Spree::Recurring::StripeRecurring.create!(name: 'Test recurring', active: true, preferred_secret_key: 'test_secret_key') }

  it { Spree::Recurring::StripeRecurring::WEBHOOKS.should eq(['customer.subscription.deleted', 'customer.subscription.created', 'customer.subscription.updated', 'invoice.payment_succeeded', 'invoice.payment_failed', 'charge.succeeded', 'charge.failed', 'charge.refunded', 'charge.captured', 'plan.created', 'plan.updated', 'plan.deleted']) }
  it { Spree::Recurring::StripeRecurring::INTERVAL.should eq({day: 'Daily', week: 'Weekly', month: 'Monthly', year: 'Annually' }) }
  it { Spree::Recurring::StripeRecurring::CURRENCY.should eq({ usd: 'USD', gbp: 'GBP', jpy: 'JPY', eur: 'EUR', aud: 'AUD', hkd: 'HKD', sek: 'SEK', nok: 'NOK', dkk: 'DKK', pen: 'PEN', cad: 'CAD'})}

  describe '#after_initialize set_api_key' do
    it 'should set_api_key' do
      Stripe.api_key.should be_nil
      stripe_recurring
      Stripe.api_key.should eq('test_secret_key')
    end
  end
end