RSpec.describe Presenters::ContentEmbed::EmailAddressPresenter do
  let(:email_address) { "foo@example.com" }
  let(:edition) { build(:edition, document_type: "content_block_email_address", details: { email_address: }) }

  it "should render with the email address" do
    presenter = described_class.new(edition)

    expect(presenter.render).to eq("<span class=\"content-embed content-embed__content_block_email_address\">#{email_address}</span>")
  end
end
