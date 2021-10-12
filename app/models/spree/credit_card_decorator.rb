Spree::CreditCard.class_eval do
  after_save do |card|
    card.verify_new_default_card
  end

  before_destroy do |card|
    card.delete_stripe_card
  end

  def create_stripe_card_token(cvc)
    card_obj = {
      number: number,
      exp_month: month,
      exp_year: year,
      cvc:  cvc,
      name: name
    } 

    if address_id.present?
      address = Spree::Address.find(address_id)

      address_obj = {
        address_line1: address.address1,
        address_line2: address.address2,
        address_city:  address.city,
        address_state: address.state.name,
        address_zip:   address.zipcode,
        address_country: address.country.name 
      }
      card_obj.merge!(address_obj)
    end

    Stripe::Token.create({card: card_obj})
  end

  def verify_new_default_card
    return unless saved_change_to_default

    if saved_change_to_default[1]
      user.credit_cards.default do |card|
        break if card.id.eql?(id)
        card.set_default!(false);
      end
    end
  end

  def set_default!(bool)
    return if default.eql?(bool)
    update(default: bool);
    save!
  end

  def delete_stripe_card
    begin
      return if gateway_customer_profile_id.nil? || gateway_payment_profile_id.nil?
      deleted_card = Stripe::Customer.delete_source(
        gateway_customer_profile_id,
        gateway_payment_profile_id,
      )
      user.get_stripe_default_card.set_default!(true)
      return true
    rescue Exception => error
      cards = user.list_stripe_cards
      raise ArgumentError.new("La tarjeta no pudo ser eliminada.") if cards.data.filter{|card| card.id == gateway_payment_profile_id}.present?
    end
  end
end
