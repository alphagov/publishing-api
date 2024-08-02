RSpec.describe "Metrics rake tasks" do
  describe "metrics:report_to_prometheus" do
    let(:task) { Rake::Task["metrics:report_to_prometheus"] }
    before { task.reenable }

    it "outputs empty metrics when there are no editions" do
      expect { task.invoke }.to output(<<~PROMETHEUS).to_stdout
        Found 0 combinations of labels
        # TYPE editions_in_database_total gauge
        # HELP editions_in_database_total Count of editions in various databases labeled by state, document_type etc.
      PROMETHEUS
    end

    it "outputs edition count metrics" do
      5.times do
        create(:draft_edition, document_type: "press_release", publishing_app: "whitehall")
      end

      10.times do
        create(:live_edition, document_type: "services_and_information", publishing_app: "publisher")
      end

      expect { task.invoke }.to output(<<~PROMETHEUS).to_stdout
        Found 2 combinations of labels
        # TYPE editions_in_database_total gauge
        # HELP editions_in_database_total Count of editions in various databases labeled by state, document_type etc.
        editions_in_database_total{database="publishing-api",state="draft",content_store="draft",document_type="press_release",publishing_app="whitehall",locale="en"} 5.0
        editions_in_database_total{database="publishing-api",state="published",content_store="live",document_type="services_and_information",publishing_app="publisher",locale="en"} 10.0
      PROMETHEUS
    end
  end
end
