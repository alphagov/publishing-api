module Events
  class S3Importer
    def initialize(s3_key)
      @s3_key = s3_key
    end

    def import
      file = Zlib::GzipReader.new(object.get.body)
      csv = CSV.new(file, headers: true)
      csv.each do |row|
        event = Event.find_or_initialize_by(id: row["id"])
        event.update!(attributes(row))
      end
      csv.rewind
      csv.count
    end

  private

    attr_reader :s3_key

    def object
      @object ||= begin
        object = bucket.object(s3_key)
        unless object.exists?
          raise EventsImportExistsError.new("S3 does not have an import for #{s3_key}")
        end
        object
      end
    end

    def bucket
      bucket_name = Rails.application.config.s3_export.bucket
      raise BucketNotConfiguredError.new("A bucket has not been configured") unless bucket_name.present?
      @bucket ||= s3.bucket(bucket_name)
    end

    def s3
      @s3 ||= Aws::S3::Resource.new(region: Rails.application.config.s3_export.region)
    end

    def attributes(row)
      json_fields = Event.columns.select { |e| e.type == :json }.map(&:name)
      json = row.each_with_object({}) do |(field, value), memo|
        memo[field] = JSON.parse(value) if json_fields.include?(field)
      end
      row.to_hash.merge(json)
    end

    class BucketNotConfiguredError < RuntimeError; end
    class EventsImportExistsError < RuntimeError; end
  end
end
