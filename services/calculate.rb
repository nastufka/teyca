def calculate_for_product(item, old_summ = 0, all_cashback = 0, existed_summ = 0, all_discount = 0, all_price = 0, user_template)
  product = Product[item['id']]
  price_product = item['price'] * item['quantity']
  old_summ += price_product
  product_discount = 0
  product_cashback = 0
  is_noloyalty = false
  item['type'] = product ? product[:type] : nil
  item['value'] = product ? product[:value] : nil
  item['type_desc'] = nil
  if product
    if product[:type] == 'increased_cashback'
      product_cashback = product[:value].to_i
      item['type_desc'] = "Дополнительный кэшбек #{product[:value].to_i}%"
    elsif product[:type] == 'discount'
      product_discount = product[:value].to_i
      item['type_desc'] = "Дополнительная скидка #{product[:value].to_i}%"
    else
      is_noloyalty = true
      item['type_desc'] = "Не участвует в системе лояльности"
    end
  end
  item['discount_percent'] = product_discount
  item['discount_summ'] = price_product / 100.0 * product_discount
  all_discount += price_product / 100.0 * product_discount
  price_product = price_product - price_product / 100.0 * product_discount
  user_price = price_product
  unless is_noloyalty
    cashback_product = price_product / 100.0 * product_cashback.to_i
    user_cashback = price_product / 100.0 * user_template.cashback.to_i
    all_cashback += (cashback_product + user_cashback)
    existed_summ += price_product
    user_price = price_product - price_product / 100.0 * user_template.discount.to_i
    all_discount += price_product / 100.0 * user_template.discount.to_i
  end
  all_price += user_price
  return old_summ, all_cashback, existed_summ, all_discount, all_price, item
end