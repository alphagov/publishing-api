require 'rails_helper'

RSpec.describe Commands::PutContentWithLinks do

  describe 'call' do
    let(:content_id) { SecureRandom.uuid }

    let(:payload) {
      build(DraftContentItem)
        .as_json
        .deep_symbolize_keys
        .except(:format, :routes)
        .merge(content_id: content_id)
    }

    it "set empty links in LinkSet to an empty hash by default" do
      expect { Commands::PutContentWithLinks.new(payload.except(:links)).call(downstream: false) }.to_not raise_error

      expect(LinkSet.find_by_content_id(content_id).links).to eq({})
    end
  end
end
