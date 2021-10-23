Spree::User.class_eval do
  has_many :subscription_plans

  def find_or_create_stripe_customer(token=nil)
    return api_customer if stripe_customer_id?

    customer = if token
      Stripe::Customer.create(description: email, email: email, card: token)
    else
      Stripe::Customer.create(description: email, email: email)
    end

    update_column(:stripe_customer_id, customer.id)
    customer
  end

  def api_customer
    Stripe::Customer.retrieve(stripe_customer_id)
  end

  def find_or_create_credit_card_from_stripe_source(stripe_card)
    if stripe_card.object.eql?("card")
      card = Spree::CreditCard.find_by(gateway_payment_profile_id: stripe_card.id)
      return card unless card.nil?
      
      stripe_gateway = Spree::Gateway::StripeGateway.find_by(type: "Spree::Gateway::StripeGateway")
      credit_cards.create!({
        gateway_payment_profile_id: stripe_card.id,
        month: stripe_card.exp_month,
        year: stripe_card.exp_year,
        cc_type: stripe_card.brand.downcase,
        last_digits: stripe_card.last4,
        gateway_customer_profile_id: stripe_card.customer,
        name: stripe_card.name,
        payment_method: stripe_gateway,
        default: stripe_card.default
      })
    end
  end

  def list_stripe_cards
    Stripe::Customer.list_sources(
      stripe_customer_id,
      {object: 'card', limit: 50}
    )
  end

  def create_stripe_card(token, set_default=true)
    find_or_create_stripe_customer unless stripe_customer_id?

    stripe_payment_method = Stripe::Customer.create_source(
        stripe_customer_id,
        {source: token}
      )
    if stripe_payment_method && set_default
      is_new_default = update_spree_default_payment_method(stripe_payment_method)
      stripe_payment_method["default"] = is_new_default
    end

    find_or_create_credit_card_from_stripe_source(stripe_payment_method)

    return stripe_payment_method
  end

  def update_spree_default_payment_method(stripe_payment_method)
    return false if stripe_customer_id.nil?

    Stripe::Customer.update(
      stripe_customer_id, {
        invoice_settings: {
          default_payment_method: stripe_payment_method.id
        }
      }
    )
  end

  def get_stripe_default_card
    stripe_default_card = credit_cards.all
      .find_by(gateway_payment_profile_id: api_customer.default_source)
    stripe_default_card.set_default!(true) unless default_credit_card.id.eql?(stripe_default_card.id)
    return stripe_default_card
  end

  def get_default_credit_card
    default_credit_card || get_stripe_default_card
  end
end
