RSpec.describe Presenters::ContentEmbed::BasePresenter do
  let(:edition) { build(:edition, document_type: "something", title: "My edition") }

  it "should render with the title" do
    presenter = described_class.new(edition)

    expect(presenter.render).to eq("<span class=\"content-embed content-embed__something\">My edition</span>")
  end
end
