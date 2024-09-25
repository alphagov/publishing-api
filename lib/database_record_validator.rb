module DatabaseRecordValidator
  class << self
    def validate
      filename = "/tmp/validation_results"
      puts "\e[36mOutput will be written to #{filename}\e[0m\n\n"

      File.open(filename, "w") do |file|
        invalid_count = 0

        models.each do |model|
          puts "Validating #{model.name} (#{model.count / 1000}k records)"

          model.all.find_each.with_index do |record, index|
            unless record.valid?
              invalid_count += 1
              file.puts "#{record.class.name} id=#{record.id}: #{record.errors.full_messages}"
            end

            print "." if (index % 1000).zero?
          end

          puts
          puts
        end

        if invalid_count.zero?
          puts "\e[32mHurrah, every record is valid!\e[0m"
        else
          puts "\e[31mUh oh, there were #{invalid_count} validation errors.\e[0m"
        end
      end
    end

    def models
      Rails.application.eager_load!
      ApplicationRecord.descendants - [ActiveRecord::SchemaMigration]
    end
  end
end
