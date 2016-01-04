require 'spec_helper'

module Spree
  module Wombat
    describe PromotionSerializer, type: :serializer do
      let(:promotion_code) { Spree::PromotionCode.new( value: 'abc' ) }
      let(:promotion) { Spree::Promotion.new(name: "Promo", codes: [promotion_code]) }
      let(:serialized) { JSON.parse(PromotionSerializer.new(promotion, root: false).to_json) }
      let(:serialized_promotion_code) do
        JSON.parse(PromotionCodeSerializer.new(promotion_code, root: false).to_json)
      end

      before { promotion.build_promotion_category(name: "Category", code: "cat") }

      it { expect(serialized['codes']).to eq([serialized_promotion_code]) }
      it { expect(serialized['name']).to eq 'Promo' }
      it { expect(serialized['category_code']).to eq 'cat' }
      it { expect(serialized['category_name']).to eq 'Category' }

    end
  end
end
