require "rails_helper"

RSpec.describe "Event logging", type: :request do
  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    logs_event('PutContentWithLinks', expected_payload_proc: ->{
      content_item_without_access_limiting.deep_stringify_keys.merge("base_path" => base_path)
    })
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    logs_event('PutDraftContentWithLinks', expected_payload_proc: ->{ content_item_with_access_limiting.deep_stringify_keys.merge("base_path" => base_path) })
  end

  context "/v2/content" do
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    logs_event('PutContent', expected_payload: RequestHelpers::Mocks.v2_content_item)
  end
end
