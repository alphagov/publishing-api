RSpec.describe Queries::GetHostContent do
  describe "#call" do
    let(:organisation) do
      edition_params = {
        title: "bar",
        document: create(:document),
        document_type: "organisation",
        schema_name: "organisation",
        base_path: "/government/organisations/bar",
      }

      create(:superseded_edition, **edition_params)
      live_edition = create(:live_edition, **edition_params.merge({ user_facing_version: 2 }))
      create(:draft_edition, **edition_params.merge({ user_facing_version: 3 }))

      live_edition
    end

    let(:content_block) do
      create(:live_edition,
             document_type: "content_block_email_address",
             schema_name: "content_block_email_address",
             details: {
               "email_address" => "foo@example.com",
             })
    end

    let(:target_content_id) { content_block.content_id }

    context "when the target_content is not embedded in any live editions" do
      it "returns an empty results list" do
        target_content_id = SecureRandom.uuid
        allow(Document).to receive(:find_by).and_return(anything)

        result = described_class.new(target_content_id).call

        expect(result).to eq([])
      end
    end

    context "when there are live and draft editions that embed the target content" do
      let!(:published_host_editions) do
        create_list(:live_edition, 2,
                    details: {
                      body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
                    },
                    links_hash: {
                      primary_publishing_organisation: [organisation.content_id],
                      embed: [target_content_id],
                    },
                    publishing_app: "example-app")
      end

      let!(:draft_host_editions) do
        create_list(:edition, 2,
                    details: {
                      body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
                    },
                    links_hash: {
                      primary_publishing_organisation: [organisation.content_id],
                      embed: [target_content_id],
                    },
                    publishing_app: "another-app")
      end

      let!(:unwanted_edition) { create(:live_edition) }

      it "returns the live editions" do
        published_host_editions.map do |edition|
          create(:statistics_cache, document: edition.document, unique_pageviews: 123)
        end

        expected_editions = published_host_editions
        expected_pageviews = StatisticsCache.where(document: published_host_editions.map(&:document))
                                            .map { |s|
                                              [s.document_id, s.unique_pageviews]
                                            }.to_h

        results = described_class.new(target_content_id).call

        expect(results.count).to eq(expected_editions.count)

        expected_editions.each_with_index do |host_edition, i|
          expect(results[i].id).to eq(host_edition.id)
          expect(results[i].title).to eq(host_edition.title)
          expect(results[i].base_path).to eq(host_edition.base_path)
          expect(results[i].document_type).to eq(host_edition.document_type)
          expect(results[i].publishing_app).to eq(host_edition.publishing_app)
          expect(results[i].host_content_id).to eq(host_edition.content_id)
          expect(results[i].primary_publishing_organisation_content_id).to eq(organisation.content_id)
          expect(results[i].primary_publishing_organisation_title).to eq(organisation.title)
          expect(results[i].primary_publishing_organisation_base_path).to eq(organisation.base_path)
          expect(results[i].unique_pageviews).to eq(expected_pageviews[host_edition.document.id])
          expect(results[i].instances).to eq(1)
        end
      end

      it "allows filtering by host_content_id" do
        host_edition = published_host_editions[1]
        results = described_class.new(target_content_id, host_content_id: host_edition.content_id).call

        expect(results.count).to eq(1)

        expect(results[0].id).to eq(host_edition.id)
        expect(results[0].title).to eq(host_edition.title)
        expect(results[0].base_path).to eq(host_edition.base_path)
        expect(results[0].document_type).to eq(host_edition.document_type)
        expect(results[0].publishing_app).to eq(host_edition.publishing_app)
        expect(results[0].host_content_id).to eq(host_edition.content_id)
        expect(results[0].primary_publishing_organisation_content_id).to eq(organisation.content_id)
        expect(results[0].primary_publishing_organisation_title).to eq(organisation.title)
        expect(results[0].primary_publishing_organisation_base_path).to eq(organisation.base_path)
        expect(results[0].instances).to eq(1)
      end
    end

    context "when the content id embedded more than once" do
      before do
        create(:live_edition,
               details: {
                 body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
               },
               links_hash: {
                 primary_publishing_organisation: [organisation.content_id],
                 embed: [target_content_id, target_content_id],
               },
               publishing_app: "example-app")
      end

      it "returns instance counts correctly" do
        results = described_class.new(target_content_id).call

        expect(results[0].instances).to eq(2)
      end
    end

    context "when an organisation has a translation" do
      let(:welsh_document) { create(:document, locale: "cy", content_id: organisation.content_id) }

      before do
        create(:live_edition, document: welsh_document, base_path: "#{organisation.base_path}.cy")
        create(:live_edition,
               details: {
                 body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
               },
               links_hash: {
                 primary_publishing_organisation: [organisation.content_id],
                 embed: [target_content_id],
               },
               publishing_app: "example-app")
      end

      it "returns one row per content block" do
        results = described_class.new(target_content_id).call

        expect(results.count).to eq(1)
      end
    end

    context "when there are superseded editions that embed the target content" do
      it "does not return the superseded editions" do
        target_content_id = content_block.content_id
        _superseded_host_edition = create(:gone_edition,
                                          details: {
                                            body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
                                          },
                                          links_hash: {
                                            primary_publishing_organisation: [organisation.content_id],
                                            embed: [content_block.content_id],
                                          })

        results = described_class.new(target_content_id).call

        expect(results.count).to eq(0)
      end
    end

    context "sorting" do
      let(:target_content_id) { SecureRandom.uuid }

      it "sorts by unique_pageviews by default" do
        expect_sort_call_for(order_field: Queries::GetHostContent::ORDER_FIELDS[:unique_pageviews], order_direction: :asc)

        described_class.new(target_content_id).call
      end

      it "allows searching in descending order with the default field" do
        expect_sort_call_for(order_field: Queries::GetHostContent::ORDER_FIELDS[:unique_pageviews], order_direction: :desc)

        described_class.new(target_content_id, order_direction: :desc).call
      end

      it "throws an error with an invalid field" do
        expect {
          described_class.new(target_content_id, order_field: :foo).call
        }.to raise_error(KeyError, "Unknown order field: foo")
      end

      it "throws an error with an invalid order direction" do
        expect {
          described_class.new(target_content_id, order_direction: :foo).call
        }.to raise_error(KeyError, "Unknown order direction: foo")
      end

      it "sorts with null fields at the bottom" do
        edition1 = create(:live_edition, links_hash: { embed: [target_content_id] }, title: "Edition 1")
        edition2 = create(:live_edition, links_hash: { embed: [target_content_id] }, title: "Edition 2")
        edition3 = create(:live_edition, links_hash: { embed: [target_content_id] }, title: "Edition 3")

        create(:statistics_cache, document: edition2.document, unique_pageviews: 123)
        create(:statistics_cache, document: edition3.document, unique_pageviews: 2)

        results = described_class.new(target_content_id, order_direction: :desc).call

        expect(results.count).to eq(3)

        expect(results[0].title).to eq(edition2.title)
        expect(results[0].unique_pageviews).to eq(123)

        expect(results[1].title).to eq(edition3.title)
        expect(results[1].unique_pageviews).to eq(2)

        expect(results[2].title).to eq(edition1.title)
        expect(results[2].unique_pageviews).to eq(nil)
      end

      Queries::GetHostContent::ORDER_FIELDS.each do |key, order_field|
        Queries::GetHostContent::ORDER_DIRECTIONS.each do |order_direction|
          it "allows searching by #{key} #{order_direction}" do
            expect_sort_call_for(order_field:, order_direction:)

            described_class.new(target_content_id, order_field: key, order_direction:).call
          end
        end
      end

      def expect_sort_call_for(order_field:, order_direction:)
        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.orders.length).to eq(1)
          if order_direction == :asc
            expect(arel_query.orders[0]).to be_a(Arel::Nodes::Ascending)
            expect(arel_query.orders[0].expr).to eq(order_field)
          else
            expect(arel_query.orders[0]).to be_a(Arel::Nodes::NullsLast)
            expect(arel_query.orders[0].expr).to be_a(Arel::Nodes::Descending)
            expect(arel_query.orders[0].expr.expr).to eq(order_field)
          end
        }.and_return([])
      end
    end

    context "pagination" do
      let(:target_content_id) { SecureRandom.uuid }

      before do
        allow(ActiveRecord::Base.connection).to receive(:select_value).and_return(232)
      end

      it "returns the count" do
        expect(described_class.new(target_content_id).count).to eq(232)
      end

      it "returns the total number of pages" do
        expect(described_class.new(target_content_id).total_pages).to eq(24)
      end

      it "requests the first page by default" do
        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.offset).to eq(0)
          expect(arel_query.limit).to eq(Queries::GetHostContent::DEFAULT_PER_PAGE)
        }.and_return([])

        described_class.new(target_content_id).call
      end

      it "accepts a page argument" do
        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.offset).to eq(10)
          expect(arel_query.limit).to eq(Queries::GetHostContent::DEFAULT_PER_PAGE)
        }.and_return([])

        described_class.new(target_content_id, page: 1).call
      end

      it "accepts a per_page argument" do
        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.offset).to eq(0)
          expect(arel_query.limit).to eq(1)
        }.and_return([])

        described_class.new(target_content_id, per_page: 1).call
      end

      it "accepts a per_page and page argument" do
        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.offset).to eq(5)
          expect(arel_query.limit).to eq(5)
        }.and_return([])

        described_class.new(target_content_id, per_page: 5, page: 1).call

        expect(ActiveRecord::Base.connection).to receive(:select_all) { |arel_query|
          expect(arel_query.offset).to eq(10)
          expect(arel_query.limit).to eq(5)
        }.and_return([])

        described_class.new(target_content_id, per_page: 5, page: 2).call
      end
    end
  end

  describe "#rollup" do
    let(:organisation1) { create(:live_edition) }
    let(:organisation2) { create(:live_edition) }

    let(:content_block) do
      create(:live_edition,
             document_type: "content_block_email_address",
             schema_name: "content_block_email_address",
             details: {
               "email_address" => "foo@example.com",
             })
    end

    let(:target_content_id) { content_block.content_id }

    it "returns a count of embedded editions" do
      statistics_caches = []

      edition1 = create(:live_edition, links_hash: {
        primary_publishing_organisation: [organisation1.content_id],
        embed: [target_content_id, target_content_id],
      })

      statistics_caches << create(:statistics_cache, document: edition1.document, unique_pageviews: 12)

      edition2 = create(:live_edition, links_hash: {
        primary_publishing_organisation: [organisation1.content_id],
        embed: [target_content_id],
      })

      statistics_caches << create(:statistics_cache, document: edition2.document, unique_pageviews: 7)

      edition3 = create(:live_edition, links_hash: {
        primary_publishing_organisation: [organisation2.content_id],
        embed: [target_content_id],
      })

      statistics_caches << create(:statistics_cache, document: edition3.document, unique_pageviews: 7)

      result = described_class.new(target_content_id).rollup

      expect(result.views).to eq(statistics_caches.sum(&:unique_pageviews))
      expect(result.locations).to eq(3)
      expect(result.instances).to eq(4)
      expect(result.organisations).to eq(2)
    end
  end
end
