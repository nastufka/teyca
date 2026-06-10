# Loyalty Service

REST API для расчета скидок, кэшбека и подтверждения операций в программе лояльности.

## Технологии

* Ruby 3.x
* Sinatra
* SQLite
* Sequel

## Структура проекта

```text
.
├── app.rb
├── config.ru
├── Gemfile
├── db
│   └── test.db
├── models
│   └── models.rb
├── services
│   └── calculate.rb
└── README.md
```

## Установка

Установить зависимости:

```bash
bundle install
```

## Запуск приложения

```bash
rackup
```

По умолчанию приложение будет доступно по адресу:

```text
http://127.0.0.1:9292
```

---

# API

## Расчет операции

### Запрос

```http
POST /calculate
Content-Type: application/json
```

```json
{
  "user_id": 1,
  "positions": [
    {
      "id": 1,
      "price": 100,
      "quantity": 3
    },
    {
      "id": 2,
      "price": 50,
      "quantity": 2
    },
    {
      "id": 3,
      "price": 40,
      "quantity": 1
    },
    {
      "id": 4,
      "price": 150,
      "quantity": 2
    }
  ]
}
```

### Ответ

```json
{
  "status": 200,
  "operation_id": 42,
  "summ": 734.0,
  "discount": {
    "summ": 6.0,
    "value": "0.81%"
  },
  "cashback": {
    "existed_summ": 10000,
    "allowed_summ": 434.0,
    "value": "4.19%",
    "will_add": 31
  }
}
```

---

## Подтверждение операции

### Запрос

```http
POST /confirm
Content-Type: application/json
```

```json
{
  "user": {
    "id": 1,
    "template_id": 1,
    "name": "Иван",
    "bonus": "9667.0"
  },
  "operation_id": 42,
  "write_off": 150
}
```

### Ответ

```json
{
  "status": 200,
  "message": "Данные успешно обработаны!",
  "operation": {
    "user_id": 1,
    "cashback": 24,
    "cashback_percent": 0,
    "discount": "6.0",
    "discount_percent": "0.81",
    "write_off": 150,
    "check_summ": 584
  }
}
```

---

# Транзакции

Все операции изменения данных выполняются внутри транзакции:

```ruby
DB.transaction do
  operation.update(...)
  user.update(...)
end
```

Если во время выполнения возникает ошибка, все изменения откатываются автоматически.

---

# Особенности реализации

* Используется ORM Sequel.
* Все ответы возвращаются в формате JSON.
* Расчеты выполняются с учетом уровня лояльности пользователя.
* Поддерживаются дополнительные правила товаров.
* Реализовано подтверждение операций со списанием бонусов.
* Для обеспечения целостности данных используются транзакции SQLite.
