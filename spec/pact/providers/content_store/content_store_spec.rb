require 'pact/rspec'

# Declaration of a consumer test, always include the :pact tag
# This is used in CI/CD pipelines to separate Pact tests from other RSpec tests
# Pact tests are not run as part of the general RSpec pipeline
RSpec.describe "SomePactConsumerTestForAnyTransport", :pact do
  # declaration of the type of interaction - here we determine which consumer and provider interact on which transport
  has_http_pact_between "CONSUMER-NAME", "PROVIDER-NAME", opts: {
    mock_port: 3093
  }

  # the context for one of the interactions, for example GET /api/v2/stores
  context "when a content item exists that has an older payload_version than the request" do
      let(:interaction) do
        # creating a new interaction - within which we describe the contract
        super()
          .given("a content item exists with base_path /vat-rates and payload_version 0")
          .upon_receiving("a request to create a content item")
          .with(
            method: :put,
            path: "/content/vat-rates",
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
      end

      it "executes the pact test without errors" do
        interaction.execute do
          expect(make_request).to be_success
        end
      end

      # it "accepts in-order messages to the content store" do | mock_server |
      #   response = subject.put_content_item(base_path: "/vat-rates", content_item: body)
      #   expect(response.code).to eq(200)
      # end

      # it "accepts in-order messages to the content store" do | mock_server |
      #   interaction.execute do
      #     # the url of the started mock server, you should pass this into your api client in the next step
      #     mock_server_url = mock_server.url
      #     # here our client is called for the API being tested
      #     # in this context, the client can be: http client
      #     # expect(make_request).to be_success
      #     response = client.put_content_item(base_path: mock_server.url, content_item: body)
      #     expect(response.code).to eq(200)
      #   end
      # end
    end
  end
