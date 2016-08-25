require "rails_helper"

RSpec.describe Queries::GetGroupedContentAndLinks do
  let(:ordered_content_ids) do
    %w(
      5f612a9f-7d3f-4b4c-a35e-ebd0b1e79019
      fd161210-3e12-41e7-8e5e-c8cef607a95f
    )
  end

  describe "#call" do
    context "when no results exist" do
      it "returns an empty array" do
        expect(subject.call).to be_empty
      end
    end

    def create_content_items(quantity)
      quantity.times do
        FactoryGirl.create(
          :content_item,
          base_path: "/random-base-path-#{Random.rand}",
        )
      end
    end

    context "when many content ids are returned" do
      it "returns content ids in lexicographic order" do
        create_content_items(described_class::PAGE_SIZE + 1)

        content_ids = subject.call.map { |result| result['content_id'] }
        content_ids.each_cons(2) do |a, b|
          expect(a).to be < b
        end
      end
    end

    context "when no pagination is specified" do
      it "returns page with default page size" do
        create_content_items(described_class::PAGE_SIZE + 1)
        expect(subject.call.size).to eql(described_class::PAGE_SIZE)
      end
    end

    context "when retrieving the next page" do
      it "returns items after last seen" do
        item = FactoryGirl.create(
          :content_item,
          base_path: '/random',
          content_id: ordered_content_ids.first
        )

        item2 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.last
        )

        results = described_class.new(last_seen_content_id: item.content_id).call

        expect(results.size).to eq(1)
        expect(results[0]["content_id"]).to eql(item2.content_id)
      end
    end

    context "when there are documents" do
      before do
        @content_item = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.first,
          base_path: "/capital-gains-tax",
          state: "published"
        )
      end

      context "with no links" do
        it "returns a single result hash" do
          results = subject.call

          expect(results.size).to eq(1)
          expect(results.first["content_id"]).to eq(@content_item.content_id)
        end

        it "returns the content item" do
          results = subject.call
          result = results.first
          content_item = result["content_items"].first

          expect(content_item).not_to be_nil
          expect(content_item["locale"]).to eq("en")
          expect(content_item["base_path"]).to eq("/capital-gains-tax")
          expect(content_item["state"]).to eq("published")
          expect(content_item["user_facing_version"]).to eq("1")
        end

        it "returns an empty array for the links" do
          results = subject.call
          result = results.first

          expect(result).to include("links")
          expect(result["links"]).to eq([])
        end
      end

      context "with links" do
        let(:target_content_id) { SecureRandom.uuid }

        before do
          FactoryGirl.create(
            :link_set,
            content_id: ordered_content_ids.first,
            links_hash: {
              "topics" => [
                target_content_id
              ]
            }
          )
        end

        it "returns an array of links" do
          results = subject.call
          expect(results.size).to eq(1)
          expect(results[0]).to include("links")
          expect(results[0]["links"]).to eq(
            [
              {
                "content_id" => ordered_content_ids.first,
                "link_type"  => "topics",
                "target_content_id" => target_content_id,
              }
            ]
          )
        end
      end

      context "with multiple editions (draft & published)" do
        before do
          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.first,
            base_path: "/vat-rates",
            state: "published"
          )

          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.first,
            base_path: "/vat-rates",
            state: "draft"
          )

          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.last,
            base_path: "/register-to-vote",
            state: "published"
          )
        end

        context "with no links" do
          it "returns the content item with empty links" do
            results = subject.call

            expect(results.size).to eq(2)
            expect(results[0]).to include("links")
            expect(results[0]["links"]).to eq([])

            expect(results[1]).to include("links")
            expect(results[1]["links"]).to eq([])
          end
        end

        context "with links" do
          let(:first_target_content_id) { SecureRandom.uuid }
          let(:second_target_content_id) { SecureRandom.uuid }

          before do
            FactoryGirl.create(
              :link_set,
              links_hash: {
                "topics" => [
                  first_target_content_id
                ]
              },
              content_id: ordered_content_ids.first
            )

            FactoryGirl.create(
              :link_set,
              links_hash: {
                "topics" => [
                  second_target_content_id
                ]
              },
              content_id: ordered_content_ids.last
            )
          end

          it "returns the content item with links" do
            results = subject.call

            expect(results.size).to eq(2)
            expect(results[0]).to include("links")
            expect(results[0]["links"]).to eq([
              {
                "content_id" => ordered_content_ids.first,
                "link_type" => "topics",
                "target_content_id" => first_target_content_id,
              }
            ])

            expect(results[1]).to include("links")
            expect(results[1]["links"]).to eq([
              {
                "content_id" => ordered_content_ids.last,
                "link_type" => "topics",
                "target_content_id" => second_target_content_id,
              }
            ])
          end
        end
      end
    end
  end
end
