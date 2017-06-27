desc "Export the taxonomy event log"
task taxonomy_event_log: [:environment] do
  events = TaxonomyEventLog.new.export

  file = CSV.generate(headers: true) do |csv|
    csv << events.first.keys

    events.each do |event|
      csv << event.values
    end
  end

  puts file
end
