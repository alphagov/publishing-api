RSpec.describe Sources::LinkedToEditionsSource do
  it "should get ministers in a single, fast query" do
    ministers_index = Edition.includes(:document).live.find_by(base_path: "/government/ministers", document: { locale: "en" })
    expect(ministers_index).to_not be_nil

    instance = described_class.new(content_store: "live", locale: "en")

    ministers_links = [
      [ministers_index, "ordered_also_attends_cabinet"],
      [ministers_index, "ordered_assistant_whips"],
      [ministers_index, "ordered_baronesses_and_lords_in_waiting_whips"],
      [ministers_index, "ordered_cabinet_ministers"],
      [ministers_index, "ordered_house_lords_whips"],
      [ministers_index, "ordered_house_of_commons_whips"],
      [ministers_index, "ordered_junior_lords_of_the_treasury_whips"],
      [ministers_index, "ordered_ministerial_departments"],
    ]

    result = instrument { instance.fetch(ministers_links) }

    expect(result.queries).to contain_exactly(
      include(sql: a_string_matching(/SELECT "editions"\.\*/)),
    )
    expect(result.queries).to all(be_fast_query(threshold: 0.05))
    expect(result).to be_fast_overall(threshold: 0.2)
  end
end
