require "rails_helper"

RSpec.describe Queries::GetLatest do
  let(:document_a) { FactoryGirl.create(:document) }
  let(:document_b) { FactoryGirl.create(:document) }
  let(:document_b_fr) do
    FactoryGirl.create(:document, content_id: document_b.content_id, locale: "fr")
  end
  let(:document_c) { FactoryGirl.create(:document) }

  before do
    FactoryGirl.create(:live_edition, document: document_a, user_facing_version: 2, base_path: "/a2")
    FactoryGirl.create(:superseded_edition, document: document_a, user_facing_version: 1, base_path: "/a1")
    FactoryGirl.create(:draft_edition, document: document_a, user_facing_version: 3, base_path: "/a3")

    FactoryGirl.create(:live_edition, document: document_b, user_facing_version: 1, base_path: "/b1")
    FactoryGirl.create(:live_edition, document: document_b_fr, user_facing_version: 2, base_path: "/b2")

    FactoryGirl.create(:live_edition, document: document_c, user_facing_version: 1, base_path: "/c1")
    FactoryGirl.create(:draft_edition, document: document_c, user_facing_version: 2, base_path: "/c2")
  end

  def base_paths(result)
    result.map(&:base_path)
  end

  it "returns a scope of the latest editions for the given scope" do
    scope = Edition.all
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/a3", "/b1", "/b2", "/c2"])

    scope = scope.joins(:document)
      .where('documents.content_id': [document_a.content_id, document_b.content_id])
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/a3", "/b1", "/b2"])

    scope = scope.where('documents.locale': 'fr')
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/b2"])
  end
end
