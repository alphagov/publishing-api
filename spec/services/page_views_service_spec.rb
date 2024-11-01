require "google/cloud/bigquery"
require "googleauth"

RSpec.describe PageViewsService do
  let(:paths) { %w[foo bar] }
  let(:start_date) { "2024-01-01" }
  let(:end_date) { "2024-01-31" }

  around do |example|
    Timecop.travel Date.parse(end_date) do
      example.run
    end
  end

  describe "#call" do
    let(:client_email) { "foo@example.com" }
    let(:private_key) { "PRIVATE_KEY" }
    let(:project_id) { "some-project-id" }
    let(:credentials) do
      {
        "client_email" => client_email,
        "private_key" => private_key,
      }
    end

    let(:creds_stub) { double(Google::Auth::ServiceAccountCredentials) }
    let(:bigquery_stub) { double(Google::Cloud::Bigquery, query: nil) }
    let(:stub_response) do
      [
        {
          cleaned_page_location: "foo",
          unique_pageviews: 123,
        },
        {
          cleaned_page_location: "bar",
          unique_pageviews: 345,
        },
      ]
    end

    def stub_creds
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds) { |args|
        args[:json_key_io].read == StringIO.new(credentials.to_json).read &&
          args[:scope] == PageViewsService::SCOPE
      }.and_return(creds_stub)
    end

    def stub_big_query
      allow(Google::Cloud::Bigquery).to receive(:new).with(
        project_id:,
        credentials: creds_stub,
      ).and_return(bigquery_stub)
      allow(bigquery_stub).to receive(:query).with(
        PageViewsService::SQL,
        params: { paths:, start_date:, end_date: },
      ).and_return(stub_response)
    end

    before do
      stub_creds
      stub_big_query
    end

    it "returns results from BigQuery" do
      ClimateControl.modify BIGQUERY_PROJECT_ID: project_id, BIGQUERY_CLIENT_EMAIL: client_email, BIGQUERY_PRIVATE_KEY: private_key do
        result = PageViewsService.new(paths:).call

        expect(result.count).to eq(2)
        expect(result.first.path).to eq("foo")
        expect(result.first.page_views).to eq(123)
        expect(result.last.path).to eq("bar")
        expect(result.last.page_views).to eq(345)
      end
    end

    it "logs a message and returns an empty array if BigQuery credentials are not found" do
      ClimateControl.modify BIGQUERY_PROJECT_ID: nil, BIGQUERY_CLIENT_EMAIL: nil, BIGQUERY_PRIVATE_KEY: nil do
        allow(Rails.logger).to receive(:info)

        result = PageViewsService.new(paths:).call

        expect(result).to eq([])
        expect(Rails.logger).to have_received(:info).with("BigQuery credentials not found - skipping job")
      end
    end
  end
end
