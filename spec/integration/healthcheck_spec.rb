require 'rails_helper'

describe "healthcheck", :type => :request do
  it "should respond with a 200" do
    get "/healthcheck"

    expect(response.status).to eq(200)
  end
end
