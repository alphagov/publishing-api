RSpec.describe "Update missing last_edited_at timestamp for specialist publisher documents" do
  describe "update_missing_last_edited_at_timestamp" do
    let(:task) { Rake::Task["update_missing_last_edited_at_timestamp"] }

    before { task.reenable }

    it "it outputs successful update information" do
      edition = create(:edition, document_type: "aaib_report", last_edited_at: nil)

      expect { task.invoke }.to output(<<~PROMETHEUS).to_stdout
        Updating last_edited_at to #{edition.updated_at} for edition ID: #{edition.id}, type: #{edition.document_type}
      PROMETHEUS
    end

    it "it outputs failed update information" do
      edition = create(:edition, document_type: "aaib_report", last_edited_at: nil)
      allow_any_instance_of(Edition)
        .to receive(:update_column)
              .and_return(false)

      expect { task.invoke }.to output(<<~PROMETHEUS).to_stdout
        Updating last_edited_at to #{edition.updated_at} for edition ID: #{edition.id}, type: #{edition.document_type}
        Failed to update edition ID: #{edition.id}
      PROMETHEUS
    end
  end
end
