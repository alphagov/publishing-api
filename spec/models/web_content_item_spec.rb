require 'rails_helper'

RSpec.describe WebContentItem do
  let(:hash) do
    {
      id: 1,
      analytics_identifier: '',
      content_id: SecureRandom.uuid,
      description: 'description',
      details: { body: 'A body' },
      document_type: 'manual',
      first_published_at: '2016-12-07T14:30:00Z',
      last_edited_at: '2016-12-07T14:48:00Z',
      need_ids: [],
      phase: 'live',
      public_updated_at: '2016-12-07T14:48:00Z',
      publishing_app: 'collections-publisher',
      redirects: [],
      rendering_app: 'government-frontend',
      routes: [],
      schema_name: 'manual',
      title: 'A Title',
      update_type: 'minor',
      base_path: 'base-path',
      locale: 'en',
      state: 'unpublished',
      user_facing_version: 1,
      unpublishing_type: 'withdrawal',
    }
  end

  subject { described_class.from_hash(hash) }

  context 'when withdrawn' do
    it { expect(subject.withdrawn?).to be_truthy }
  end
end
