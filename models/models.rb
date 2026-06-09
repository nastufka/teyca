require_relative '../config/database'

class Operation < Sequel::Model(:operations)
  many_to_one :user
end

class Product < Sequel::Model(:products)
end

class User < Sequel::Model(:users)
  many_to_one :template
end

class Template < Sequel::Model(:templates)
end