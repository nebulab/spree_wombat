require 'active_model/serializer'

module Spree
  module Wombat
    class PromotionCodeSerializer < ActiveModel::Serializer
      attributes :value
    end
  end
end
