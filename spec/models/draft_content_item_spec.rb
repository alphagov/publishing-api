require 'rails_helper'

RSpec.describe DraftContentItem do
  def verify_new_attributes_set
    expect(described_class.first.title).to eq("New title")
  end

  def verify_old_attributes_not_preserved
    expect(described_class.first.format).to be_nil
    expect(described_class.first.routes).to eq([])
  end

  let(:new_attributes) {
    {
      content_id: content_id,
      title: "New title",
    }
  }

  it_behaves_like Replaceable
end
