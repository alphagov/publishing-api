require 'rails_helper'

RSpec.describe Link do

  let(:valid_uuid) { "df633bb7-8825-4cf6-96dd-752c9949da69" }
  let(:valid_link_type) { "organisations" }

  describe "validating link_type" do
    it "allows link types that are underscored alphanumeric" do
      [
        'word',
        'word2word',
        'word_word',
      ].each do |link_type|
        link = Link.create(link_type: link_type, target_content_id: valid_uuid)
        expect(link).to be_valid
      end
    end

    it "rejects link types with non-allowed characters" do
      [
        'Uppercase',
        'space space',
        'dash-ed',
        'punctuation!',
        '',
      ].each do |link_type|
        link = Link.create(link_type: link_type, target_content_id: valid_uuid)
        expect(link).not_to be_valid, "expected item not to be valid with links_type '#{link_type}'"
        expect(link.errors[:link]).to eq(["Invalid link type: #{link_type}"])
      end
    end

    it "rejects reserved link type available_translations" do
      link = Link.create(link_type: "available_translations", target_content_id: valid_uuid)
      expect(link).not_to be_valid, "expected item not to be valid with links key 'available_translations'"
      expect(link.errors[:link]).to eq(["Invalid link type: available_translations"])
    end
  end

  describe "validating target_content_id" do
    it 'rejects non-UUID content IDs' do
      link = Link.create(link_type: valid_link_type, target_content_id: "this-id-is-not-an-uuid")
      expect(link).not_to be_valid
      expect(link.errors[:link]).to eq(["target_content_id must be a valid UUID"])
    end
  end
end
