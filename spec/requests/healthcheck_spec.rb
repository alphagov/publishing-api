require "rails_helper"

RSpec.describe "/healthcheck", type: :request do
  def data(body = response.body)
    JSON.parse(body).deep_symbolize_keys
  end

  it "should respond with ok" do
    get "/healthcheck"

    expect(response.status).to eq(200)
    expect(data.keys).to include(:checks, :status)
  end

  it "includes each check" do
    get "/healthcheck"

    expect(data.fetch(:checks).keys).to include(
      :database_connectivity,
      :redis_connectivity,
      :sidekiq_queue_latency
    )
  end
end
