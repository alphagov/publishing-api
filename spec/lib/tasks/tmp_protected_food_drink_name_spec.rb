require "rails_helper"

RSpec.describe "rake protected_food_drink_name:update_registered_details", rake_task: true do
  let(:task) { Rake::Task["protected_food_drink_name:update_registered_details"] }

  before :each do
    task.reenable # without this, calling `invoke` does nothing after first test
  end

  it "changes the date_registration and time_registration for registered wines and uk-gi-before-2021" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "wines",
          status: "registered",
          reason_for_protection: "uk-gi-before-2021",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2021-03-10")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to be_nil
  end

  it "changes the date_registration and time_registration for registered traditional-terms-for-wine and uk-gi-before-2021" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "traditional-terms-for-wine",
          status: "registered",
          reason_for_protection: "uk-gi-before-2021",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2021-03-10")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to be_nil
  end

  it "changes the date_registration and time_registration for registered wines and eu-agreement" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "wines",
          status: "registered",
          reason_for_protection: "eu-agreement",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2021-03-10")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to be_nil
  end

  it "changes the date_registration and time_registration for registered traditional-terms-for-wine and eu-agreement" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "traditional-terms-for-wine",
          status: "registered",
          reason_for_protection: "eu-agreement",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2021-03-10")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to be_nil
  end

  it "does not change the date_registration and time_registration for other registered names" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "not-wine",
          status: "registered",
          reason_for_protection: "eu-agreement",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2019-12-31")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to eq("23:00")
  end

  it "does not change the date_registration and time_registration for other reason for protection" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "wines",
          status: "registered",
          reason_for_protection: "uk-trade-agreement",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2019-12-31")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to eq("23:00")
  end

  it "does not change the date_registration and time_registration for unregistered names" do
    edition = create(
      :edition,
      document_type: "protected_food_drink_name",
      details: {
        metadata: {
          date_registration: "2019-12-31",
          time_registration: "23:00",
          register: "wines",
          status: "draft",
        },
      },
    )

    stub_content_store_calls(edition.base_path)

    task.invoke

    expect(edition.reload.details.dig(:metadata, :date_registration)).to eq("2019-12-31")
    expect(edition.reload.details.dig(:metadata, :time_registration)).to eq("23:00")
  end

  def stub_content_store_calls(base_path)
    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end
end
