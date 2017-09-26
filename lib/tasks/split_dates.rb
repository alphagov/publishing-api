module Tasks
  class SplitDates
    def self.populate_threaded(number_of_threads = 5)
      response = threaded_documents_iterate(number_of_threads) do |from_id, until_id, thread_number|
        populate(
          from_id: from_id,
          until_id: until_id,
          thread: thread_number,
        )
      end

      puts "Completed populating dates in #{response[:time_elapsed]}"
    end

    def self.populate(from_id: nil, until_id: nil, thread: nil)
      iterate_documents_with_progress(
        from_id: from_id, until_id: until_id, thread: thread
      ) do |document|
        PopulateDocument.new(document).call
      end

      prefix = thread ? "Thread #{thread}. " : ""

      puts "#{prefix}Completed populating dates"
    end

    def self.validate
      total = Edition.count
      start = Time.now
      invalid = 0
      Edition.select(
        :id,
        :document_id,
        :first_published_at,
        :publisher_first_published_at,
        :temporary_first_published_at,
        :public_updated_at,
        :publisher_major_published_at,
        :major_published_at,
        :last_edited_at,
        :publisher_last_edited_at,
        :temporary_last_edited_at
      ).find_each.with_index do |e, index|
        invalid += e.new_dates_valid? ? 0 : 1
        completed = index + 1

        if (completed % 10000).zero?
          time = time_remaining(start, completed, total)

          puts "Progress: #{completed}/#{total} editions (#{invalid} invalid), approximately #{time} remaining."
        end
      end

      puts "Completed validing edition dates #{invalid}/#{total} are invalid."
    end

    def self.threaded_documents_iterate(number_of_threads)
      ids = Document.order(id: :asc).pluck(:id)
      start_time = Time.now

      raise "No documents to iterate through" if ids.count.zero?

      per_thread = (ids.count.to_f / number_of_threads).ceil
      groups = ids.each_slice(per_thread)
      responses = []
      threads = groups.map.with_index(1) do |thread_ids, number|
        Thread.new do
          from_id = thread_ids.first unless number == 1
          until_id = thread_ids.last unless number == groups.count

          responses[number] = yield(from_id, until_id, number)
        end
      end

      threads.each(&:join)
      seconds_elapsed = Time.now.to_i - start_time.to_i
      time_elapsed = Time.at(seconds_elapsed).utc.strftime("%H:%M:%S")

      { time_elapsed: time_elapsed, thread_responses: responses }
    end

    def self.iterate_documents_with_progress(
      from_id: nil, until_id: nil, thread: nil
    )
      scope = Document
      scope = scope.where("id >= ?", from_id) if from_id
      scope = scope.where("id <= ?", until_id) if until_id

      count = scope.count
      start = Time.now
      prefix = thread ? "Thread #{thread}. " : ""

      scope.find_each.with_index do |document, index|
        yield(document)
        completed = index + 1
        if (completed % 100).zero?
          time = time_remaining(start, completed, count)

          puts "#{prefix}Progress: #{completed}/#{count} documents, approximately #{time} remaining."
        end
      end
    end

    def self.time_remaining(start_time, completed, total)
      seconds_elapsed = Time.now.to_i - start_time.to_i
      per_second = seconds_elapsed.to_f / completed
      remaining_time = per_second * (total - completed)
      # This won't work if it's over 24 hours, but that's probably a bigger problem
      Time.at(remaining_time).utc.strftime("%H:%M:%S")
    end

    def self.reset_document(document)
      Edition.where(document: document).update_all(
        temporary_first_published_at: nil,
        publisher_first_published_at: nil,
        major_published_at: nil,
        publisher_major_published_at: nil,
        published_at: nil,
        publisher_published_at: nil,
        temporary_last_edited_at: nil,
        publisher_last_edited_at: nil
      )
    end
  end
end

require_dependency "tasks/split_dates/populate_document"
