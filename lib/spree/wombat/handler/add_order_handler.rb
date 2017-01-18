module Spree
  module Wombat
    module Handler
      class AddOrderHandler < OrderHandlerBase

        def process
          Spree::Order.transaction do
            payload = @payload[:order]
            order_params = OrderHandlerBase.order_params(payload)

            adjustment_attrs = []

            shipping_adjustment = nil
            tax_adjustment = nil

            # remove possible shipment adjustment here
            order_params["adjustments_attributes"].each do |adjustment|
              case adjustment["label"].downcase
              when "shipping"
                shipping_adjustment = adjustment
              else
                adjustment_attrs << adjustment unless adjustment["label"].downcase == "shipping"
              end
            end

            order_params["adjustments_attributes"] = adjustment_attrs if adjustment_attrs.present?

            order = nil

            Spree::Order.skip_single_cart_validation do
              order = Spree::Core::Importer::Order.import(find_spree_user, order_params.deep_symbolize_keys)
            end

            order.reload

            number_of_shipments_created = order.shipments.count
            shipping_cost = payload["totals"]["shipping"]
            shipping_method = Spree::ShippingMethod.find_by!(name: payload["shipping_method"])
            order.shipments.each do |shipment|
              cost_per_shipment = BigDecimal.new(shipping_cost.to_s) / number_of_shipments_created
              shipment.shipping_rates.where.not(shipping_method_id: shipping_method).destroy_all
              shipment.shipping_rates.where(shipping_method_id: shipping_method).update_all selected: true
              shipment.update_columns(cost: cost_per_shipment)
            end

            order.updater.update_shipment_total
            order.updater.update_payment_state
            order.updater.persist_totals
            response "Order number #{order.number} was added", 200, Base.wombat_objects_for(order.reload)
          end
        end

        private

        def find_spree_user
          Spree.user_class.where(email: @payload[:order][:email]).first_or_create
        end

      end
    end
  end
end
