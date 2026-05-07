RSpec.describe "Sidekiq old jobs", type: :request do
  describe "GET /sidekiq/old_locks" do
    before { get "/sidekiq/old_locks" }

    it "responds with a 200" do
      expect(response.status).to eq(200)
    end

    it "presents information about old locks" do
      expect(response.body).to include("Old locks")
    end
  end

  describe "GET /sidekiq/old_locks/:digest" do
    before { get "/sidekiq/old_locks/uniquejobs:f2f8d140b3191770c992ad238c95dbb9" }

    it "responds with a 200" do
      expect(response.status).to eq(200)
    end

    it "presents information about a specific old lock" do
      expect(response.body).to include(
        "Old lock information for digest uniquejobs:f2f8d140b3191770c992ad238c95dbb9",
      )
    end
  end
end
