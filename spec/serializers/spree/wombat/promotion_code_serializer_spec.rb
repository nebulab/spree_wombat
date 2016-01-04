require 'spec_helper'

module Spree
  module Wombat
    describe PromotionSerializer, type: :serializer do
      let(:promotion_code) { Spree::PromotionCode.new( value: 'abc' ) }
      let(:serialized) do
        JSON.parse(PromotionCodeSerializer.new(promotion_code, root: false).to_json)
      end

      it { expect(serialized['value']).to eq('abc') }
    end
  end
end
