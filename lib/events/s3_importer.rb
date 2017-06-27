require 'csv'

module Events
  class S3Importer
    def import_from_s3_by_key(s3_key)
      import_file(object(s3_key).get.body)
    end

    def import_by_path(path)
      import_file(File.new(path))
    end

  private

    def import_file(zipfile)
      file = Zlib::GzipReader.new(zipfile)
      csv = CSV.new(file, headers: true)
      csv.each do |row|
        if true # replace this with a conditional, or you'll have to import all events
          event = Event.find_or_initialize_by(id: row["id"])
          if event.payload.present?
            print 'o'
            next
          end

          event.update!(attributes(row))
          print "x"
        else
          print "-"
        end
      end
    end

    def object(s3_key)
      bucket.object(s3_key).tap do |object|
        unless object.exists?
          raise EventsImportExistsError.new("S3 does not have an import for #{s3_key}")
        end
      end
    end

    def bucket
      bucket_name = Rails.application.config.s3_export.bucket
      raise BucketNotConfiguredError.new("A bucket has not been configured") unless bucket_name.present?
      @bucket ||= s3.bucket(bucket_name)
    end

    def s3
      @s3 ||= Aws::S3::Resource.new
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
