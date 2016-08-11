require 'rails_helper'

RSpec.describe DataHygiene::DuplicateContentItem do
  subject(:duplicate_checker) { described_class.new }
  let(:content_id) { SecureRandom.uuid }

  before do
    FactoryGirl.create(:content_item, content_id: content_id, base_path: '/test')
    duplicate = FactoryGirl.build(:content_item, content_id: content_id, base_path: '/test')
    duplicate.save(validate: false)
    s = State.new(content_item_id: duplicate.id, name: 'draft')
    s.save(validate: false)
    l = Location.new(content_item_id: duplicate.id, base_path: '/test')
    l.save(validate: false)
    u = UserFacingVersion.new(content_item_id: duplicate.id, number: 1)
    u.save(validate: false)
    u = Translation.new(content_item_id: duplicate.id, locale: 'en')
    u.save(validate: false)
  end

  it 'logs to errbit when there are duplicate content items' do
    expect(Airbrake).to receive(:notify_or_ignore)
    duplicate_checker.check
  end
end
