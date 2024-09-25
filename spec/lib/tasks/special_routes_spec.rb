RSpec.describe "Rake tasks for publishing special routes" do
  context "with special routes data" do
    let(:stdout) { double(:stdout, puts: nil) }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:replacement_special_routes_file) do
      YAML.load_file(Rails.root.join("spec/fixtures/special_routes.yaml"))
    end

    before do
      original_special_routes_path = Rails.root.join("lib/data/special_routes.yaml")
      allow(YAML).to receive(:load_file).with(original_special_routes_path).and_return(replacement_special_routes_file)
    end

    describe "special_routes:publish" do
      before do
        Rake::Task["special_routes:publish"].reenable
      end

      it "publishes the special routes, except the homepage" do
        Rake::Task["special_routes:publish"].invoke

        expect(Document.count).to eq(3)
        expect(Edition.count).to eq(3)
        expect(Edition.all.collect(&:title)).to eq(["Account home page", "Save a page", "Government Uploads"])
      end
    end

    describe "special_routes:publish_for_app" do
      before do
        Rake::Task["special_routes:publish_for_app"].reenable
      end

      it "publishes the special routes for one particular app without publishing others or the homepage" do
        Rake::Task["special_routes:publish_for_app"].invoke("frontend")

        expect(Document.count).to eq(2)
        expect(Edition.count).to eq(2)
        expect(Edition.all.collect(&:title)).to eq(["Account home page", "Save a page"])
      end

      it "returns a message if there are no routes for that app" do
        expect(Rails.logger).to receive(:info).with(/No routes for finder-frontend in lib\/data\/special_routes.yaml/)

        Rake::Task["special_routes:publish_for_app"].invoke("finder-frontend")

        expect(Document.count).to eq(0)
      end
    end

    describe "special_routes:publish_one_route" do
      before do
        Rake::Task["special_routes:publish_one_route"].reenable
      end

      it "publishes one special route" do
        Rake::Task["special_routes:publish_one_route"].invoke("/account/saved-pages/add")

        expect(Document.count).to eq(1)
        expect(Edition.count).to eq(1)
        edition = Edition.where(title: "Save a page").first
        expect(edition).not_to be_nil
      end

      it "returns a message if there are no records for that path" do
        expect(Rails.logger).to receive(:info).with(/Route needs to be added to \/lib\/data\/special_routes.yaml/)

        Rake::Task["special_routes:publish_one_route"].invoke("/account/saved-pages/remove")

        expect(Document.count).to eq(0)
      end
    end

    describe "special_routes:unpublish_one_route" do
      before do
        Rake::Task["special_routes:publish_one_route"].reenable
        Rake::Task["special_routes:publish_one_route"].invoke("/media")
        Rake::Task["special_routes:unpublish_one_route"].reenable
      end

      it "unpublishes one special route" do
        expect(Edition.first.state).to eq("published")

        Rake::Task["special_routes:unpublish_one_route"].invoke("/media")

        expect(Edition.first.state).to eq("unpublished")
      end

      it "unpublishes one special route with a redirect" do
        expect(Edition.first.state).to eq("published")

        Rake::Task["special_routes:unpublish_one_route"].invoke("/media", "/media2")

        expect(Edition.first.state).to eq("unpublished")
      end

      it "returns a message if there are no records for that path" do
        expect(Edition.first.state).to eq("published")
        expect(Rails.logger).to receive(:info).with(/Route needs to be added to \/lib\/data\/special_routes.yaml/)

        Rake::Task["special_routes:unpublish_one_route"].invoke("/account/saved-pages/remove")

        expect(Edition.first.state).to eq("published")
      end
    end

    describe "special_routes:publish_homepage" do
      before do
        Rake::Task["special_routes:publish_homepage"].reenable
      end

      it "publishes the homepage, and nothing else" do
        Rake::Task["special_routes:publish_homepage"].invoke

        expect(Document.count).to eq(1)
        expect(Edition.count).to eq(1)
        edition = Edition.where(title: "GOV.UK homepage").first
        expect(edition).not_to be_nil
      end
    end
  end
end
