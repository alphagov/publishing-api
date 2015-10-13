require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

  def verify_new_attributes_set
    expect(described_class.first.title).to eq("New title")
  end

  def validates_base_path
    create(:live_content_item, content_id: '123', base_path: '/foo')
    build(:draft_content_item, content_id: '123', base_path: '/bar').should_not be_valid
  end

  let(:new_attributes) {
    {
      content_id: content_id,
      title: "New title",
    }
  }

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
end
