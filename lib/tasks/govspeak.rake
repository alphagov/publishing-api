namespace :govspeak do
  task :compare, [:publishing_app, :limit, :offset, :order] => :environment do |_, args|
    args.with_defaults(order: "content_items.id ASC")
    scope = State.joins(:content_item)
    scope = scope.where(content_items: { publishing_app: args[:publishing_app] }) if args[:publishing_app].present?
    scope = scope.where(name: %w(published unpublished draft))
    scope = scope.limit(args[:limit]) if args[:limit].present?
    scope = scope.offset(args[:offset]) if args[:offset].present?
    scope = scope.order(args[:order])
    total = scope.count
    same_html = 0
    trivial_differences = 0
    scope.each do |state|
      content_item = state.content_item
      comparer = DataHygiene::GovspeakCompare.new(content_item)
      same_html += 1 if comparer.same_html?
      trivial_differences += 1 if !comparer.same_html? && comparer.pretty_much_same_html?
      next if comparer.pretty_much_same_html?
      state = State.where(content_item_id: content_item.id).pluck(:name).first
      base_path = Location.where(content_item_id: content_item.id).pluck(:base_path).first
      puts "Content Item #{content_item.id} #{content_item.content_id} #{state} #{base_path}"
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
