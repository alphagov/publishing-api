require "rails_helper"

RSpec.describe Events::S3Importer do
  def gzipped_file(contents)
    string_io = StringIO.new
    gzip = Zlib::GzipWriter.new(string_io)
    gzip.write(contents)
    gzip.finish
    string_io.rewind
    string_io
  end

  let(:resource) { Aws::S3::Resource.new(client: client) }
  let(:client) { Aws::S3::Client.new(region: "eu-west-1", stub_responses: true) }
  let(:s3_key) { "events/2015-11-12T00:00:00+00:00.csv.gz" }
  let(:file) { gzipped_file(file_contents) }
  let(:file_contents) do
    <<-CSV.strip_heredoc
      id,action,temp_payload,payload,user_uid,created_at,updated_at,request_id,content_id
      10,Publish,"{""content_id"":""2cc503f1-5fef-4fac-8381-63f6689cd6a2""}","{""content_id"":""2cc503f1-5fef-4fac-8381-63f6689cd6a2""}",,2015-11-11 09:55:00 UTC,2015-11-11 09:55:00 UTC,,2cc503f1-5fef-4fac-8381-63f6689cd6a2
      11,Publish,"{""content_id"":""8bc0c1dd-4842-4283-a123-5671a34b67eb""}","{""content_id"":""8bc0c1dd-4842-4283-a123-5671a34b67eb""}",e676cb22-0c0c-4534-9514-a65ebcc7a9e2,2015-11-11 14:00:00 UTC,2015-11-11 14:00:00 UTC,2027-1477408502.282-80.194.77.100-1361,8bc0c1dd-4842-4283-a123-5671a34b67eb
    CSV
  end
  let(:event_10_attributes) do
    {
      id: 10,
      action: "Publish",
      temp_payload: { "content_id" => "2cc503f1-5fef-4fac-8381-63f6689cd6a2" },
      payload: { "content_id" => "2cc503f1-5fef-4fac-8381-63f6689cd6a2" },
      user_uid: nil,
      created_at: Time.zone.local(2015, 11, 11, 9, 55),
      updated_at: Time.zone.local(2015, 11, 11, 9, 55),
      request_id: nil,
      content_id: "2cc503f1-5fef-4fac-8381-63f6689cd6a2",
      temp_payload: { "content_id" => "2cc503f1-5fef-4fac-8381-63f6689cd6a2" },
    }
  end
  let(:event_11_attributes) do
    {
      id: 11,
      action: "Publish",
      temp_payload: { "content_id" => "8bc0c1dd-4842-4283-a123-5671a34b67eb" },
      payload: { "content_id" => "8bc0c1dd-4842-4283-a123-5671a34b67eb" },
      user_uid: "e676cb22-0c0c-4534-9514-a65ebcc7a9e2",
      created_at: Time.utc(2015, 11, 11, 14),
      updated_at: Time.utc(2015, 11, 11, 14),
      request_id: "2027-1477408502.282-80.194.77.100-1361",
      content_id: "8bc0c1dd-4842-4283-a123-5671a34b67eb",
      temp_payload: { "content_id" => "8bc0c1dd-4842-4283-a123-5671a34b67eb" },
    }
  end

  before do
    allow(Aws::S3::Resource).to receive(:new).and_return(resource)
    client.stub_responses(:get_object, body: file)
  end

  describe "#import" do
    subject(:importer) { described_class.new }

    context "when the events do not exist in our database" do
      it "creates the events" do
        expect(Event.where(id: [10, 11]).count).to eq 0
        importer.import(s3_key)
        expect(Event.where(id: [10, 11]).count).to eq 2
      end

      it "it sets the expected attributes" do
        importer.import(s3_key)
        expect(Event.find(10).attributes).to match(event_10_attributes.stringify_keys)
        expect(Event.find(11).attributes).to match(event_11_attributes.stringify_keys)
      end

      it "returns the number of imported items" do
        expect(importer.import(s3_key)).to be 2
      end
    end

    context "when the events exist in our database" do
      let!(:event_10) { create(:event, id: 10) }
      let!(:event_11) { create(:event, id: 11) }

      it "updates the events" do
        expect(Event.where(id: [10, 11]).count).to eq 2
        importer.import(s3_key)
        expect(Event.where(id: [10, 11]).count).to eq 2
      end

      it "it sets the expected attributes" do
        importer.import(s3_key)
        expect(Event.find(10).attributes).to match(event_10_attributes.stringify_keys)
        expect(Event.find(11).attributes).to match(event_11_attributes.stringify_keys)
      end

      it "returns the number of imported items" do
        expect(importer.import(s3_key)).to be(2)
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
          importer.import(s3_key)
        }.to raise_error(described_class::BucketNotConfiguredError, "A bucket has not been configured")
      end
    end

    context "when the object doesn't exist" do
      before do
        client.stub_responses(:head_object, status_code: 404, headers: {}, body: "")
      end

      it "raises a EventsImportExistsError" do
        expect {
          importer.import(s3_key)
        }.to raise_error(described_class::EventsImportExistsError, "S3 does not have an import for #{s3_key}")
      end
    end
  end
end
