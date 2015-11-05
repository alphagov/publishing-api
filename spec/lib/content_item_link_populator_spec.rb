require 'rails_helper'

RSpec.describe ContentItemLinkPopulator do

  let!(:source_content_id) { SecureRandom.uuid }

  let!(:link_content_id_1) { SecureRandom.uuid }
  let!(:link_content_id_2) { SecureRandom.uuid }

  describe "adding linked items with same key" do

    let!(:links) {
      { organisations: [ link_content_id_1, link_content_id_2 ] }
    }

    it "creates 2 linked items with same link_type" do
      ContentItemLinkPopulator.create_or_replace(source_content_id, links)
      first_link = ContentItemLink.first
      second_link = ContentItemLink.last

      expect(first_link.source).to eq source_content_id
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target).to eq link_content_id_1

      expect(second_link.source).to eq source_content_id
      expect(second_link.link_type).to eq "organisations"
      expect(second_link.target).to eq link_content_id_2
    end
  end

  describe "adding linked items with different keys" do
    let!(:links) {
      {
        organisations: [ link_content_id_1 ],
        related_links: [ link_content_id_2 ],
      }
    }

    it "creates 2 linked items with different link_type" do
      ContentItemLinkPopulator.create_or_replace(source_content_id, links)
      first_link = ContentItemLink.first
      second_link = ContentItemLink.last

      expect(first_link.source).to eq source_content_id
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target).to eq link_content_id_1


      expect(second_link.source).to eq source_content_id
      expect(second_link.link_type).to eq "related_links"
      expect(second_link.target).to eq link_content_id_2
    end
  end

  describe "adding the same set of linked items twice" do
    let!(:links) {
      {
        organisations: [ link_content_id_1 ],
        related_links: [ link_content_id_2 ],
      }
    }

    it "copies are not stored to the database" do
      ContentItemLinkPopulator.create_or_replace(source_content_id, links)
      ContentItemLinkPopulator.create_or_replace(source_content_id, links)
      first_link = ContentItemLink.first
      second_link = ContentItemLink.last

      expect(first_link.source).to eq source_content_id
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target).to eq link_content_id_1


      expect(second_link.source).to eq source_content_id
      expect(second_link.link_type).to eq "related_links"
      expect(second_link.target).to eq link_content_id_2

      expect(ContentItemLink.all.count).to eq 2
    end
  end

  describe "updating an existent set of linked items" do
    let!(:first_set) {
      {
        organisations: [ link_content_id_1 ],
        related_links: [ link_content_id_2 ],
      }
    }

    describe "with different keys" do
      let!(:second_set) {
        {
          organisations: [ link_content_id_1, link_content_id_2 ],
        }
      }

      it "updates the links" do
        ContentItemLinkPopulator.create_or_replace(source_content_id, first_set)
        ContentItemLinkPopulator.create_or_replace(source_content_id, second_set)
        first_link = ContentItemLink.first
        second_link = ContentItemLink.last

        expect(first_link.source).to eq source_content_id
        expect(first_link.link_type).to eq "organisations"
        expect(first_link.target).to eq link_content_id_1


        expect(second_link.source).to eq source_content_id
        expect(second_link.link_type).to eq "organisations"
        expect(second_link.target).to eq link_content_id_2

        expect(ContentItemLink.all.count).to eq 2
      end
    end

    describe "with an empty set of links" do
      let!(:second_set) { {} }

      it "removes linked items" do
        ContentItemLinkPopulator.create_or_replace(source_content_id, first_set)

        expect(ContentItemLink.all.count).to eq 2

        ContentItemLinkPopulator.create_or_replace(source_content_id, second_set)

        expect(ContentItemLink.all.count).to eq 0
      end
    end
  end

  describe "handling a nil value for links" do

    let!(:links_1) { nil }

    it "does not create new linked items" do
      ContentItemLinkPopulator.create_or_replace(source_content_id, links_1)

      expect(ContentItemLink.all.count).to eq 0
    end
  end

end
