require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

  def verify_new_attributes_set
    expect(described_class.first.title).to eq("New title")
  end

  let(:new_attributes) {
    {
      content_id: content_id,
      title: "New title",
    }
  }

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
