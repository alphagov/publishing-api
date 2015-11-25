require 'rails_helper'

RSpec.describe Presenters::Queries::LinkSetPresenter do
  describe ".present" do
    before do
      FactoryGirl.create(:version, target: link_set, number: 101)
      @result = Presenters::Queries::LinkSetPresenter.present(link_set)
    end

    let(:link_set) { FactoryGirl.create(:link_set, content_id: "foo") }

    it "returns link set attributes as a hash" do
      expect(@result.fetch(:content_id)).to eq("foo")
    end

    it "exposes the version of the link set" do
      expect(@result.fetch(:version)).to eq(101)
    end
  end

  describe "#links" do
    it "exposes the version of the link set" do
      link_set = create(:link_set, links: { "topics" => ["778decfb-3e9c-490d-bbd5-9eeb76ee9016"]})

      presenter = Presenters::Queries::LinkSetPresenter.new(link_set)

      expect(presenter.links).to eq({ topics: ["778decfb-3e9c-490d-bbd5-9eeb76ee9016"] })
    end
  end
end
