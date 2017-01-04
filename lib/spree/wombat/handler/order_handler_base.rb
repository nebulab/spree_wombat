module Spree
  module Wombat
    module Handler
      class OrderHandlerBase < Base

        def self.order_params(order)
          order['number'] = order.delete('id')

          shipping_address_hash = order.delete('shipping_address')
          billing_address_hash = order.delete('billing_address')

          prepare_address(shipping_address_hash, 'ship_address_attributes')
          prepare_address(billing_address_hash, 'bill_address_attributes')

          payments_attributes = order.fetch('payments', [])
          placed_on = order.delete('placed_on')

          adjustments_attributes_hash = prepare_adjustments order.fetch('adjustments', [])
          line_items_hash = rehash_line_items(order['line_items'])
          line_items_hash = Hash[ line_items_hash.each_with_index.map{|item, index| [index, item]} ]

          order = order.slice *Spree::Order.attribute_names

          order['ship_address_attributes'] = shipping_address_hash
          order['bill_address_attributes'] = billing_address_hash

          order['line_items_attributes'] = line_items_hash
          order['adjustments_attributes'] = adjustments_attributes_hash
          payments_attributes.map { |payment| payment.delete("id") }
          order['payments_attributes'] = payments_attributes
          order['completed_at'] = placed_on
          order
        end

        private

        def self.prepare_address(address_hash, target_key)
          address_hash['country_id'] = Spree::Country.find_by(iso: address_hash.delete('country')).try(:id)
          address_hash['state_name'] = address_hash.delete('state')
          address_hash['phone'] ||= '(missing)'
        end

        def self.rehash_line_items(line_items)
          line_items.map do |item|
            sku = item.delete 'product_id'
            item = item.slice *Spree::LineItem.attribute_names
            item['variant_id'] = Spree::Variant.find_by!(sku: sku).id
            item
          end
        end

        def self.prepare_adjustments(adjustments)
          adjustments.map do |adjustment|
            adjustment['label'] = adjustment.delete('name') if adjustment.key?('name')
            adjustment['amount'] = adjustment.delete('value') if adjustment.key?('value')
            adjustment
          end
        end

      end
    end
  end
end
