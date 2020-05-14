require "csv"

module Events
  class S3Exporter
    def initialize(created_before, created_on_or_after = nil)
      @created_before = created_before
      @created_on_or_after = created_on_or_after
    end

    def export
      file = Tempfile.new("events_s3_#{filename}.csv.gz")
      zipped = Zlib::GzipWriter.open(file) do |gzip|
        gzip.orig_name = "#{filename}.csv"
        build_csv(gzip)
        gzip.close
      end
      upload(zipped)
      exported = event_scope.update_all(payload: nil)
      [exported, s3_key]
    end

  private

    attr_reader :created_before, :created_on_or_after

    def bucket
      bucket_name = Rails.application.config.s3_export.bucket
      raise BucketNotConfiguredError.new("A bucket has not been configured") if bucket_name.blank?

      @bucket ||= s3.bucket(bucket_name)
    end

    def s3
      @s3 ||= Aws::S3::Resource.new
    end

    def build_csv(file)
      csv = CSV.new(file)
      csv << Event.new.as_csv.keys
      event_scope.find_each do |event|
        csv << event.as_csv.values
      end
    end

    def filename
      created_before.strftime("%FT%T%:z")
    end

    def s3_key
      prefix = Rails.application.config.s3_export.events_key_prefix
      "#{prefix}#{filename}.csv.gz"
    end

    def upload(file)
      object = bucket.object(s3_key)
      raise EventsExportExistsError.new("S3 already has an export for #{object.key}") if object.exists?

      object.put(body: file, server_side_encryption: "AES256")
    end

    def event_scope
      scope = Event.where("payload IS NOT NULL AND created_at < ?", created_before)
      scope = scope.where("created_at >= ?", created_on_or_after) if created_on_or_after
      scope
    end

    class EventsExportExistsError < RuntimeError; end
    class BucketNotConfiguredError < RuntimeError; end
  end
end
