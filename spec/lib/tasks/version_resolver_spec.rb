require "rails_helper"

RSpec.describe Tasks::VersionResolver, :resolve do
  let(:content_id) { SecureRandom.uuid }

  before do
    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      state: "published",
      user_facing_version: 2,
      locale: "en"
    )

    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      state: "superseded",
      user_facing_version: 1,
      locale: "en"
    )

    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      state: "draft",
      user_facing_version: 3,
      locale: "en"
    )
  end

  context "when there are no version sequence problems" do
    it "does not resolve any versions" do
      expect { described_class.resolve }.not_to output(/Invalid version sequence/).to_stdout

      expect(UserFacingVersion.all.map(&:number).sort).to eq([1, 2, 3])
    end
  end

  context "when two items of the same content_id have identical versions" do
    let(:collision_content_item) do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        state: "superseded",
        user_facing_version: 4,
        locale: "en"
      )
    end

    before do
      UserFacingVersion.where(content_item: collision_content_item).update_all(number: 2)
    end

    it "updates the last item one version higher than its predecessor" do
      expect { described_class.resolve }.to output(
        /Resolved versions for #{content_id} from \[1, 2, 2, 3\] to \[1, 2, 3, 4\]/).to_stdout

      expect(UserFacingVersion.all.map(&:number).sort).to eq([1, 2, 3, 4])
    end
  end
end
