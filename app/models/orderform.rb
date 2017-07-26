class Orderform
  include Mongoid::Document
  field :id, type: String
  field :title, localize: true
  field :text, localize: true
  field :gid, type: String
  embeds_many :producers
end

class Producer
  include Mongoid::Document
  field :id, type: String
  field :display_order, type: Integer
  field :name, localize: true
  field :description, localize: true
  embeds_many :products
  embedded_in :orderform
end

class Product
	include Mongoid::Document
	field :id, type: String
	field :display_order, type: Integer
    field :order_column, type: Integer
	field :name, localize: true
	field :price, type: Float
	field :unit, localize: true
	field :in_bracket, localize: true
	field :remain_location, type: String
	embedded_in :producer
end