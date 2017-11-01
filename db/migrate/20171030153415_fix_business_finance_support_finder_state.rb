require 'gds_api/content_store'

class FixBusinessFinanceSupportFinderState < ActiveRecord::Migration[5.1]
  def up
    unpublished_edition = nil
    say_with_time "Checking the world is as we expect for /business-finance-support-finder before we update it" do
      content_store = GdsApi::ContentStore.new(Plek.find('content-store'))
      business_finance_support_finder = content_store.content_item('/business-finance-support-finder').to_hash
      raise "Expected /business-finance-support-finder to be a 'business_support_finder' in content_store but it's a '#{business_finance_support_finder['document_type']}'" if business_finance_support_finder['document_type'] != 'business_support_finder'

      unpublished_editions = Edition.where(base_path: '/business-finance-support-finder').where.not(state: 'superseded')
      raise "Expected 1 edition for /business-finance-support-finder but there were #{unpublished_editions.count}" if unpublished_editions.size != 1

      unpublished_edition = unpublished_editions.first
      raise "Expected /business-finance-support-finder edition to be unpublished but it was '#{unpublished_edition.state}'" if unpublished_edition.state != 'unpublished'

      raise "Expected unpublishing for /business-finance-support-finder to be a substitute, but it was '#{unpublished_edition.unpublishing.type}" if unpublished_edition.unpublishing.nil? || unpublished_edition.unpublishing.type != 'substitute'
    end

    say_with_time "Destroying substitute unpublishing for '/business-finance-support-finder'" do
      unpublished_edition.unpublishing.destroy
    end
    say_with_time "Setting state and content_store to that of a published edition for '/business-finance-support-finder'" do
      unpublished_edition.publish
    end
  end
end
