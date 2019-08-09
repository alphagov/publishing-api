require "rails_helper"

RSpec.describe Events::S3Exporter do
  let(:created_before) { Time.now }
  let(:created_on_or_after) { nil }
  let(:client) { Aws::S3::Client.new(region: "eu-west-1", stub_responses: true) }
  let(:resource) { Aws::S3::Resource.new(client: client) }
  let(:object_exists?) { false }
  let(:s3_key) { "events/#{created_before.to_s(:iso8601)}.csv.gz" }
  let(:resource_double) { instance_double("Aws::S3::Resource", bucket: bucket_double) }
  let(:bucket_double) { instance_double("Aws::S3::Bucket", object: object_double) }
  let(:object_double) do
    instance_double("Aws::S3::Object",
                    exists?: object_exists?,
                    put: Aws::S3::Types::PutObjectOutput.new)
  end

  before do
    allow(Aws::S3::Resource).to receive(:new).and_return(resource)
    unless object_exists?
      client.stub_responses(:head_object, status_code: 404, headers: {}, body: "")
    end
  end

  def build_csv(expected_events)
    columns = "id,action,payload,user_uid,created_at,updated_at,request_id,content_id\n"
    expected_events.inject(columns) do |memo, event|
      memo << CSV.generate_line([event.id, event.action, event.payload.to_json, event.user_uid, event.created_at, event.updated_at, event.request_id, event.content_id])
    end
  end

  describe "#export" do
    subject(:exporter) { described_class.new(created_before, created_on_or_after) }
    let(:theresa_may_appointed) { Time.new(2016, 7, 13, 9) }
    let(:david_cameron_appointed) { Time.new(2010, 5, 11, 9) }
    let(:gordon_brown_appointed) { Time.new(2007, 6, 27, 9) }
    let(:tony_blair_appointed) { Time.new(1997, 5, 2, 9) }

    shared_examples "uploads to S3" do
      after { exporter.export }
      let(:resource) { resource_double }

      it "gives the object a timestamp based file name" do
        expect(bucket_double).to receive(:object).with(s3_key)
      end

      it "uploads an object to S3" do
        expect(object_double).to receive(:put)
          .with(hash_including(body: an_instance_of(File)))
      end

      it "requests encryption with S3" do
        expect(object_double).to receive(:put)
          .with(hash_including(server_side_encryption: "AES256"))
      end

      it "sends a zip file with the expected content" do
        expected_body = a_gzipped_file.containing(file_contents)
        expect(object_double).to receive(:put)
          .with(hash_including(body: expected_body))
      end
    end

    shared_examples "updates records" do
      it "returns the number of archived records and the s3_key" do
        expect(exporter.export).to match([expected_archives.count, s3_key])
      end

      it "clears the payloads of archived records" do
        exporter.export
        expected_archives.each do |event|
          event.reload
          expect(event.payload).to be_nil
        end
      end
    end

    context "when there are items to export" do
      let(:created_before) { theresa_may_appointed }
      let!(:theresa_may_event) do
        create(:event,
               title: "Theresa May becomes Prime Minister",
               created_at: theresa_may_appointed)
      end
      let!(:david_cameron_event) do
        create(:event,
               title: "David Cameron becomes Prime Minister",
               created_at: david_cameron_appointed)
      end
      let!(:gordon_brown_event) do
        create(:event,
               title: "Gordon Brown becomes Prime Minister",
               created_at: gordon_brown_appointed)
      end
      let!(:tony_blair_event) do
        create(:event,
               title: "Tony Blair becomes Prime Minister",
               created_at: tony_blair_appointed)
      end

      context "and we're wanting events before Theresa May took office" do
        let(:expected_archives) { [david_cameron_event, gordon_brown_event, tony_blair_event] }
        let(:file_contents) { build_csv(expected_archives) }
        include_examples "uploads to S3"
        include_examples "updates records"
      end

      context "and we're wanting events on or after Gordon Brown took office" do
        let(:created_on_or_after) { gordon_brown_appointed }
        let(:expected_archives) { [david_cameron_event, gordon_brown_event] }
        let(:file_contents) { build_csv(expected_archives) }
        include_examples "uploads to S3"
        include_examples "updates records"

        context "but some of the items have already been exported" do
          before { david_cameron_event.update(payload: nil) }
          let(:expected_archives) { [gordon_brown_event] }
          include_examples "uploads to S3"
          include_examples "updates records"
        end
      end

      context "but there is already an export to s3" do
        let(:object_exists?) { true }

        it "raises an EventsExportExistsError" do
          expect {
            exporter.export
          }.to raise_error(described_class::EventsExportExistsError, "S3 already has an export for #{s3_key}")
        end
      end

      context "but the upload to S3 fails" do
        before do
          client.stub_responses(:put_object, status_code: 500, headers: {}, body: "")
        end

        it "raises the AWS error" do
          expect {
            exporter.export
          }.to raise_error(Aws::S3::Errors::ServiceError)
        end
      end
    end

    context "when all of the items have been exported previously" do
      let!(:david_cameron_event) do
        create(:event, payload: nil, created_at: david_cameron_appointed)
      end
      let!(:gordon_brown_event) do
        create(:event, payload: nil, created_at: gordon_brown_appointed)
      end
      let!(:tony_blair_event) do
        create(:event, payload: nil, created_at: tony_blair_appointed)
      end
      let(:created_before) { theresa_may_appointed }
      let(:file_contents) { build_csv([]) }
      include_examples "uploads to S3"

      it "returns the number of records and the s3 key" do
        expect(exporter.export).to match([0, s3_key])
      end
    end

    context "when there are no items to export" do
      let(:created_before) { theresa_may_appointed }
      let(:file_contents) { build_csv([]) }
      it "returns the number of records and the s3 key" do
        expect(exporter.export).to match([0, s3_key])
      end
    end

    context "when the bucket is not configured" do
      before do
        @bucket_name = Rails.application.config.s3_export.bucket
        Rails.application.config.s3_export.bucket = nil
      end
      after { Rails.application.config.s3_export.bucket = @bucket_name }

      it "raises a BucketNotConfiguredError" do
        expect {
          exporter.export
        }.to raise_error(described_class::BucketNotConfiguredError, "A bucket has not been configured")
      end
    end
  end
end
