require "rails_helper"

RSpec.describe OneOffRedirectFixService do
  it "should find the first non-redirect edition and update all redirects in the chain" do
    edition_1 = create(:redirect_live_edition, destination: "/redirected-path-1", base_path: "/original-base-path")
    edition_2 = create(:redirect_live_edition, destination: "/redirected-path-2", base_path: "/redirected-path-1")
    edition_3 = create(:redirect_live_edition, destination: "/redirected-path-3", base_path: "/redirected-path-2")
    edition_4 = create(:live_edition, base_path: "/redirected-path-3")

    described_class.update_redirects(edition_1)
    described_class.update_redirects(edition_2)
    described_class.update_redirects(edition_3)
    expect(edition_1.reload.redirects.first[:destination]).to eq edition_4.base_path
    expect(edition_2.reload.redirects.first[:destination]).to eq edition_4.base_path
    expect(edition_3.reload.redirects.first[:destination]).to eq edition_4.base_path
  end

  it "should not update edition if redirects path equals the destination" do
    edition_1 = create(:redirect_live_edition, destination: "/redirected-path-1", base_path: "/original-base-path")
    create(:redirect_live_edition, destination: "/original-base-path", base_path: "/redirected-path-1")

    described_class.update_redirects(edition_1)
    expect(edition_1.reload.redirects.first[:destination]).to eq "/redirected-path-1"
  end

  it "should not update redirects for English edition" do
    document = create(:document, locale: "en")
    edition_1 = create(:redirect_live_edition, destination: "/redirected-path-1", base_path: "/original-base-path", document: document)
    create(:redirect_live_edition, destination: "/redirected-path-2", base_path: "/redirected-path-1")
    create(:live_edition, base_path: "/redirected-path-2")

    described_class.fix_redirects!
    expect(edition_1.reload.redirects.first[:destination]).to eq "/redirected-path-1"
  end

  it "should update redirects for non-English edition" do
    document = create(:document, locale: "de")
    edition_1 = create(:redirect_live_edition, destination: "/redirected-path-1", base_path: "/original-base-path", document: document)
    create(:redirect_live_edition, destination: "/redirected-path-2", base_path: "/redirected-path-1")
    create(:live_edition, base_path: "/redirected-path-2")
    stub_content_store_calls(edition_1.base_path)

    described_class.fix_redirects!
    expect(edition_1.reload.redirects.first[:destination]).to eq "/redirected-path-2"
  end

  it "should avoid updating editions when any editions in the chain have more than 1 redirect" do
    edition_1 = create(:redirect_live_edition, destination: "/redirected-path-1", base_path: "/original-base-path")
    edition_2 = create(:redirect_live_edition, destination: "/redirected-path-2", base_path: "/redirected-path-1")
    edition_2.redirects = [
      { "path" => "/redirected-path-1", "type" => "exact", "destination" => "/redirected-path-2" },
      { "path" => "/redirected-path-1", "type" => "exact", "destination" => "/redirected-path-2a" },
    ]
    edition_2.save!(validate: false)
    edition_3 = create(:redirect_live_edition, destination: "/redirected-path-3", base_path: "/redirected-path-2")
    create(:live_edition, base_path: "/redirected-path-3")

    edition_1_redirects = edition_1.redirects
    edition_2_redirects = edition_2.redirects
    edition_3_redirects = edition_3.redirects

    described_class.update_redirects(edition_1)
    described_class.update_redirects(edition_2)
    described_class.update_redirects(edition_3)
    expect(edition_1.reload.redirects).to eq edition_1_redirects
    expect(edition_2.reload.redirects).to eq edition_2_redirects
    expect(edition_3.reload.redirects).to eq edition_3_redirects
  end

  def stub_content_store_calls(base_path)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end
end
