require "rails_helper"

RSpec.describe Queries::GetLinkChanges do
  describe '#as_json' do
    it 'returns the link changes with the correct data' do
      FactoryGirl.create(:link_change)

      result = Queries::GetLinkChanges.new({}, double).as_json

      change = result[:link_changes].first

      expect(change.keys).to eql(
        [:id, :source_content_id, :target_content_id, :link_type, :change, :user_uid, :created_at]
      )
    end
  end
end
