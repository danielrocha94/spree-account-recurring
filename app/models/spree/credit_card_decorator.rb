Spree::CreditCard.class_eval do
  after_save do |card|
    card.verify_new_default_card
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
end

#::Spree::CreditCard.prepend Spree::CreditCardDecorator if ::Spree::CreditCard.included_modules.exclude?(Spree::CreditCardDecorator)
