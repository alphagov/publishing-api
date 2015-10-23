require 'rails_helper'
require "govuk/client/test_helpers/url_arbiter"

RSpec.describe Commands::V2::PutContent do

  include GOVUK::Client::TestHelpers::URLArbiter

  describe 'call' do
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { '/vat-rates' }

    let(:payload) {
      build(DraftContentItem)
        .as_json
        .deep_symbolize_keys
        .except(:format, :routes)
        .merge(content_id: content_id,
               title: 'The title',
               base_path: base_path)
    }

    describe 'validation' do
      before do
        create(:url_reservation, publishing_app: payload[:publishing_app], path: base_path)
        create(:live_content_item, content_id: content_id, base_path: base_path)
      end

      context 'given a base_path change on a published item' do
        let(:updated_payload) { payload.merge(base_path: '/vatrates') }

        it 'raises an error' do
          expect { Commands::V2::PutContent.call(updated_payload) }.to raise_error(
            CommandError, 'Base path cannot be changed for published items')
        end
      end

      context 'given a publishing_app change on a published item' do
        let(:updated_payload) { payload.merge(publishing_app: 'new-publishing-app') }
        it 'raises an error' do
          expect { Commands::V2::PutContent.call(updated_payload) }.to raise_error(
            CommandError, 'Base path is already registered by mainstream_publisher')
        end
      end

      context 'given a field change on a published item' do
        before do
          stub_default_url_arbiter_responses
          stub_request(:put, %r{.*content-store.*/content/.*})
        end

        let(:updated_payload) { payload.merge(title: 'A better title') }

        it 'passes validation' do
          expect(Commands::Success).to receive(:new).with(updated_payload)

          Commands::V2::PutContent.call(updated_payload)
        end
      end
    end
  end
end
