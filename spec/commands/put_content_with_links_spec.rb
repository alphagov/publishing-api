require "rails_helper"

RSpec.describe Commands::PutContentWithLinks do
  describe "#call" do
    it "protects certain links from being overwritten" do
      stub_request(:put, "http://draft-content-store.dev.gov.uk/content/foo")
      stub_request(:put, "http://content-store.dev.gov.uk/content/foo")

      link_set = create(:link_set, content_id: '60d81299-6ae7-4bab-b4fe-4235d518d50a')
      protected_link = create(:link, link_set: link_set, link_type: 'alpha_taxons')
      normal_link = create(:link, link_set: link_set, link_type: 'topics')

      Commands::PutContentWithLinks.call({
        title: 'Test Title',
        format: 'placeholder',
        content_id: '60d81299-6ae7-4bab-b4fe-4235d518d50a',
        base_path: '/foo',
        publishing_app: 'whitehall',
        rendering_app: 'whitehall',
        public_updated_at: Time.now,
        routes: [{ path: '/foo', type: "exact" }],
      })

      expect { normal_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { protected_link.reload }.not_to raise_error
    end
  end
end
