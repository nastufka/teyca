require 'sinatra'
require_relative 'models/models'
require_relative 'services/calculate'
require 'json'

class App < Sinatra::Base
  get '/' do
    User.all.map(&:values).to_json
  end

  post '/operation' do
    begin
      DB.transaction do
        params = JSON.parse(request.body.read)
        user = User[params['user_id']]
        return { status: 404, message: 'Пользователь не найден' }.to_json if user.nil?
        user_template = user.template
        puts user_template.values
        all_price = 0
        all_cashback = 0
        all_discount = 0
        existed_summ = 0
        old_summ = 0
        positions = params['positions']
        positions.each do |i|
          old_summ, all_cashback, existed_summ, all_discount, all_price, i = calculate_for_product(i, old_summ, all_cashback, all_discount, existed_summ, all_price, user_template)
        end
        cashback_percent = (all_cashback.to_i.to_f / old_summ * 100).round(2)
        discount_percent = (all_discount / old_summ * 100).round(2)
        operation = Operation.create(
          user_id: params['user_id'],
          cashback: all_cashback.to_i,
          cashback_percent: cashback_percent,
          discount: all_discount.round(2),
          discount_percent: discount_percent,
          write_off: nil,
          check_summ: all_price.round(2),
          done: false,
          allowed_write_off: existed_summ.round(2)
        )

        { status: 200, user: user.values, operation: operation.id, summ: all_price, positions: positions,
          cashback: { existed_summ: user.bonus, allowed_summ: existed_summ,
                      value: "#{cashback_percent}%", will_add: all_cashback.to_i },
          discount: { summ: all_discount, value: "#{discount_percent}%" } }.to_json
      rescue => e
        status 500

        {
          status: 500,
          message: e.message
        }.to_json
      end
    end
  end

  post '/submit' do
    begin
      DB.transaction do
        params = JSON.parse(request.body.read)
        user = User[params['user']['id']]
        operation = Operation[params['operation_id']]
        return { status: 404, message: 'Пользователь не найден' }.to_json unless user
        return { status: 404, message: 'Операция не найдена' }.to_json unless operation
        return { status: 400, message: 'Операция уже подтверждена' }.to_json if operation.done

        new_sum = operation.check_summ.to_f - params['write_off'].to_f
        new_cashback = (new_sum.round / 100.0 * operation.cashback_percent).to_i

        user.update(
          bonus: user.bonus.to_f - params['write_off'].to_f + new_cashback
        )

        operation.update(
          write_off: params['write_off'].to_f,
          done: true
        )

        { status: 200, message: 'Данные успешно обработаны!',
          operation: { user_id: user.id, cashback: new_cashback, cashback_percent: operation.cashback_percent.to_f,
                       discount: operation.discount.to_f, discount_percent: operation.discount_percent.to_f,
                       write_off: params['write_off'].to_f, check_summ: new_sum
          }
        }.to_json
      rescue => e
        status 500

        {
          status: 500,
          message: e.message
        }.to_json
      end
    end
  end
end
