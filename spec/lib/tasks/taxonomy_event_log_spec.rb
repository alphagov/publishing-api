require "rails_helper"

RSpec.describe TaxonomyEventLog do
  before do
    Timecop.freeze("2017-01-02 12:23")
  end

  after do
    Timecop.return
  end

  it "exports all the events" do
    # Create 2 relationships
    FactoryGirl.create(:event, user_uid: 'bf61e464-aae9-4ec6-b6ae-6acfde796bdb', action: 'PatchLinkSet', content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291', payload: { links: { taxons: ['7f2a716a-e527-4485-9381-fd47cb49d30c', '396253a1-fb87-48d0-91e9-570c63166068'] } })

    # Create another relationship (which doesn't include `taxons`)
    FactoryGirl.create(:event, user_uid: 'bf61e464-aae9-4ec6-b6ae-6acfde796bdb', action: 'PatchLinkSet', content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291', payload: { links: { something_else: [] } })

    # Keep one the same and replace another
    FactoryGirl.create(:event, user_uid: 'bf61e464-aae9-4ec6-b6ae-6acfde796bdb', action: 'PatchLinkSet', content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291', payload: { links: { taxons: ['7f2a716a-e527-4485-9381-fd47cb49d30c', 'c231acfd-4cb1-427d-9b00-b67b5146ea52'] } })

    # Remove all taxons
    FactoryGirl.create(:event, user_uid: 'bf61e464-aae9-4ec6-b6ae-6acfde796bdb', action: 'PatchLinkSet', content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291', payload: { links: { taxons: [] } })

    document = FactoryGirl.create(:document, content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291')
    taggable = FactoryGirl.create(:edition, document: document, title: 'Content Foo')

    document = FactoryGirl.create(:document, content_id: '7f2a716a-e527-4485-9381-fd47cb49d30c')
    FactoryGirl.create(:edition, document: document, title: 'Taxon Foo')

    document = FactoryGirl.create(:document, content_id: 'c231acfd-4cb1-427d-9b00-b67b5146ea52')
    FactoryGirl.create(:edition, document: document, title: 'Taxon Bar')

    document = FactoryGirl.create(:document, content_id: '396253a1-fb87-48d0-91e9-570c63166068')
    FactoryGirl.create(:edition, document: document, title: 'Taxon Baz')

    diffo = TaxonomyEventLog.new.export

    base = {
      taggable_content_id: '1dd96f5d-c260-438b-ba58-57ba910e9291',
      taggable_title: 'Content Foo',
      taggable_navigation_document_supertype: 'other',
      taggable_base_path: taggable.base_path,
      tagged_at: Time.now,
      tagged_on: Date.today,
      user_uid: 'bf61e464-aae9-4ec6-b6ae-6acfde796bdb',
    }

    expect(diffo).to eql([
      base.merge(taxon_content_id: '7f2a716a-e527-4485-9381-fd47cb49d30c', taxon_title: 'Taxon Foo', change: 1),
      base.merge(taxon_content_id: '396253a1-fb87-48d0-91e9-570c63166068', taxon_title: 'Taxon Baz', change: 1),
      base.merge(taxon_content_id: 'c231acfd-4cb1-427d-9b00-b67b5146ea52', taxon_title: 'Taxon Bar', change: 1),
      base.merge(taxon_content_id: '396253a1-fb87-48d0-91e9-570c63166068', taxon_title: 'Taxon Baz', change: -1),
      base.merge(taxon_content_id: '7f2a716a-e527-4485-9381-fd47cb49d30c', taxon_title: 'Taxon Foo', change: -1),
      base.merge(taxon_content_id: 'c231acfd-4cb1-427d-9b00-b67b5146ea52', taxon_title: 'Taxon Bar', change: -1),
    ])
  end
end
