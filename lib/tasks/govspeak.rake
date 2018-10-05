require "colorize"

namespace :govspeak do
  task :compare, %i[publishing_app limit offset order] => :environment do |_, args|
    args.with_defaults(order: "editions.id ASC")
    scope = Edition.where(state: %w(published unpublished draft))
    scope = scope.where(publishing_app: args[:publishing_app]) if args[:publishing_app].present?
    scope = scope.limit(args[:limit]) if args[:limit].present?
    scope = scope.offset(args[:offset]) if args[:offset].present?
    scope = scope.order(args[:order])
    total = scope.count
    same_html = 0
    trivial_differences = 0
    scope.each do |edition|
      comparer = DataHygiene::GovspeakCompare.new(edition)
      same_html += 1 if comparer.same_html?
      trivial_differences += 1 if !comparer.same_html? && comparer.pretty_much_same_html?
      next if comparer.pretty_much_same_html?
      puts "Edition #{edition.id} #{edition.document.content_id} #{edition.state} #{edition.base_path}"
      comparer.diffs.each do |field, diff|
        next if diff == []
        puts field
        diff.each do |item|
          print item.red if item[0] == "-"
          print item.green if item[0] == "+"
        end
      end
    end
    puts "Same HTML: #{same_html}/#{total}"
    puts "Trivial Differences: #{trivial_differences}/#{total}"
    puts "Other differences: #{total - (same_html + trivial_differences)}/#{total}"
  end
end
