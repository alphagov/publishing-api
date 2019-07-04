  # @TODO Remove this file once the split dates task has run
namespace :split_dates do
  desc "Populate the split dates introduced September 2017"
  task :populate, [:threads] => :environment do |_, args|
    threads = Integer(args.fetch(:threads, 5))
    Tasks::SplitDates.populate_threaded(threads)
  end

  desc "Validate that the dates on editions are correct"
  task validate: :environment do
    Tasks::SplitDates.validate
  end

  desc "Backfill publishing_api_* dates using temporary_* dates"
  task backfill: :environment do
    scope = Edition.select(:id,
                           :temporary_first_published_at,
                           :publishing_api_first_published_at,
                           :temporary_last_edited_at,
                           :publishing_api_last_edited_at)

    total = Edition.count
    start_time = Time.current
    done = 0

    scope.find_in_batches(batch_size: 10_000) do |batch|
      batch.each do |e|
        if e.temporary_first_published_at != e.publishing_api_first_published_at ||
            e.temporary_last_edited_at != e.publishing_api_last_edited_at

          e.update_columns(
            publishing_api_first_published_at: e.temporary_first_published_at,
            publishing_api_last_edited_at: e.temporary_last_edited_at,
          )
        end
      end

      done += batch.count
      time_elapsed = Time.at(Time.current - start_time).utc.strftime("%H:%M:%S")
      puts "Processed #{done}/#{total} - time elapsed: #{time_elapsed}"
    end
  end
end
