require 'spec_helper'

module Spree
  describe Wombat::WebhookController do

    let!(:message) {
      ::Hub::Samples::Order.request
    }

    context '#consume' do
      context 'with unauthorized request' do
        let(:request_params) {
          {
            params: {
              format: :json,
              path: 'add_order',
            },
            body: ::Hub::Samples::Order.request.to_json,
          }
        }
        it 'returns 401 status' do
          post :consume, request_params
          expect(response.code).to eql "401"
          response_json = ::JSON.parse(response.body)
          expect(response_json["request_id"]).to_not be_nil
          expect(response_json["summary"]).to eql "Unauthorized!"
        end
      end

      context 'with the correct auth' do
        before do
          request.env['HTTP_X_HUB_TOKEN'] = 'abc1233'
        end

        context 'and an existing handler for the webhook' do
          let(:request_params) {
            {
              params: {
                format: :json,
                path: 'my_custom',
              },
              body: ::Hub::Samples::Order.request.to_json,
            }
          }
          it 'will process the webhook handler' do
            post 'consume', request_params
            expect(response).to be_success
          end
        end

        context 'when an exception happens' do
          let(:web_request_params) {
            {
              params: {
                format: :json,
                path: invalid_path,
              },
              body: ::Hub::Samples::Order.request.to_json,
            }
          }
          let(:web_request) do
            post 'consume', web_request_params
          end
          let(:invalid_path) { 'upblate_order' }

          it 'will return resonse with the exception message and backtrace' do
            web_request
            expect(response.code).to eql "500"
            json = JSON.parse(response.body)
            expect(json["summary"]).to eql "uninitialized constant Spree::Wombat::Handler::UpblateOrderHandler"
            expect(json["backtrace"]).to be_present
          end

          context 'with an error_notifier' do
            before { Spree::Wombat::WebhookController.error_notifier = error_notifier }
            after { Spree::Wombat::WebhookController.error_notifier = nil }
            let(:error_notifier) { -> (_responder) {} }

            it 'calls the error_notifier' do
              expect(error_notifier).to receive(:call)
              web_request
            end
          end
        end
      end
    end
  end
end
