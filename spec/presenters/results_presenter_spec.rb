RSpec.describe Presenters::ResultsPresenter do
  let(:results) { double("results", total: 10, call: []) }
  let(:page) { 2 }
  let(:pagination) { double("pagination", pages: 10, page:) }
  let(:url) { "www.example.com/v2/api/content&page=2&per_page=10" }
  subject(:presenter) { described_class.new(results, pagination, url).present }

  it "has the total result size" do
    expect(presenter[:total]).to eq(10)
  end

  it "has the result set" do
    expect(presenter[:results]).to eq([])
  end

  context "links" do
    let(:previous) { presenter[:links].detect { |link| link[:rel] == "previous" } }
    let(:self_link) { presenter[:links].detect { |link| link[:rel] == "self" } }
    let(:next_link) { presenter[:links].detect { |link| link[:rel] == "next" } }

    it "has a previous link" do
      expect(previous[:href]).to eq("www.example.com/v2/api/content&per_page=10&page=1")
    end

    it "has a self link" do
      expect(self_link[:href]).to eq("www.example.com/v2/api/content&per_page=10&page=2")
    end

    it "has a next link" do
      expect(next_link[:href]).to eq("www.example.com/v2/api/content&per_page=10&page=3")
    end

    context "no page" do
      let(:page) { 1 }
      let(:url) { "www.example.com/v2/api/content&per_page=10" }

      it "adds the correct page number" do
        expect(next_link[:href]).to match(/page=2/)
      end
    end

    context "first page" do
      let(:page) { 1 }

      it "has no previous link" do
        expect(previous).to_not be
      end
    end

    context "last page" do
      let(:page) { 10 }

      it "has no next link" do
        expect(next_link).to_not be
      end
    end
  end
end
