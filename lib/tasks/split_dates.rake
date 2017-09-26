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
end
