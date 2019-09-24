require "rails_helper"

RSpec.describe Tasks::DatabaseRecordValidator do
  let!(:valid_record) { create(:path_reservation) }

  context "when all records are valid" do
    it "prints to stdout" do
      expect {
        subject.validate
      }.to output(/every record is valid/).to_stdout
    end
  end

  context "when there are invalid records" do
    let!(:invalid_record) do
      invalid_record = build(:path_reservation, base_path: "invalid")
      invalid_record.save!(validate: false)
      invalid_record
    end

    it "prints to stdout and logs to /tmp/validation_results" do
      expect {
        subject.validate
      }.to output(/validation errors/).to_stdout

      output = File.read("/tmp/validation_results")
      expect(output).to eq(
        "PathReservation id=#{invalid_record.id}: [\"Base path is not a valid absolute URL path\"]\n",
      )
    end
  end
end
