require "rails_helper"

RSpec.describe "rake international_development_funds:update_value_of_funding", rake_task: true do
  let(:task) { Rake::Task["international_development_funds:update_value_of_funding"] }

  before :each do
    task.reenable # without this, calling `invoke` does nothing after first test
  end

  it "changes the value_of_funding for existing editions where appropriate" do
    edition = create(
      :edition,
      document_type: "international_development_fund",
      details: { metadata: { value_of_funding: %w[up-to-100000] } },
    )

    task.invoke

    expect(edition.reload.details[:metadata][:value_of_funding]).to eq(%w[10001-to-100000])
  end

  it "does not change the value_of_funding for the values that are unchanged" do
    unchanged_values = %w[
      up-to-10000
      10001-to-100000
      100001-500000
      500001-to-1000000
      more-than-1000000
    ]
    editions = unchanged_values.map do |val|
      create(
        :edition,
        document_type: "international_development_fund",
        details: { metadata: { value_of_funding: [val] } },
      )
    end

    task.invoke

    unchanged_values.each_with_index do |val, index|
      expect(editions[index].reload.details[:metadata][:value_of_funding]).to eq([val])
    end
  end

  it "does not change the value_of_funding for editions if they are not of type international_development_fund" do
    edition = create(
      :edition,
      document_type: "services_and_information",
      details: { metadata: { value_of_funding: %w[up-to-100000] } },
    )

    task.invoke

    expect(edition.reload.details[:metadata][:value_of_funding]).to eq(%w[up-to-100000])
  end

  it "does not lose other metadata that exist in the 'details'" do
    edition = create(
      :edition,
      document_type: "international_development_fund",
      details: {
        metadata: {
          value_of_funding: %w[up-to-100000],
          foo: "bar",
        },
        bar: "baz",
      },
    )

    task.invoke

    expect(edition.reload.details).to eq({
      metadata: {
        value_of_funding: %w[10001-to-100000],
        foo: "bar",
      },
      bar: "baz",
    })
  end
end
