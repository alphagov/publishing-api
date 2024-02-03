def print_links_graphviz(path, nodes, parent, key, links)
  # Maximum for each key, otherwise the graph is just silly
  links.take(3).each do |link|
    content_id = link.fetch(:content_id)
    label = link[:title]
    label = link[:base_path] if label.blank?
    label = content_id if label.blank?
    unless nodes.include?("#{path}/#{key}")
      puts "\"#{path}/#{key}\" [label=\"#{key}\" shape=box]"
      puts "\"#{parent}\" -> \"#{path}/#{key}\""
      nodes << "#{path}/#{key}"
    end
    unless nodes.include?(content_id)
      puts "\"#{content_id}\" [label=\"#{label}\" shape=box]"
      nodes << content_id
    end
    puts "\"#{path}/#{key}\" -> \"#{content_id}\""

    children = link[:links]
    next if children.nil?

    children.each do |(child_key, child_links)|
      print_links_graphviz("#{path}/#{key}/#{content_id}", nodes, content_id, child_key, child_links)
    end
  end
end

namespace :graphviz do
  desc "Print the ExpansionRules::MULTI_LEVEL_LINK_PATHS in Graphviz dot format"
  task :expansion_rules, [] => :environment do
    mlps = ExpansionRules::MULTI_LEVEL_LINK_PATHS

    puts "digraph {"
    mlps.each_with_index do |path, i|
      path.each do |elem|
        if elem.is_a? Symbol
          puts "\"p#{i+1} #{elem}\" [label = \"#{elem}\"]"
        elsif elem.is_a? Array
          puts "\"p#{i+1} #{elem.first}\" [label = \"#{elem.first}\"]"
        else
          raise "Unexpected element type #{elem.class}"
        end
      end
      path.prepend("root").each_cons(2) do |from, to|
        target = to.is_a?(Array) ? to.first : to
        case from
        when "root"
          # puts "root -> \"p#{i+1} #{target}\""
        when Symbol
          puts "\"p#{i+1} #{from}\" -> \"p#{i+1} #{target}\""
        when Array
          puts "\"p#{i+1} #{from.first}\" -> \"p#{i+1} #{target}\""
        end
        if to.is_a? Array
          puts "\"p#{i+1} #{target}\" -> \"p#{i+1} #{target}\""
        end
      end
    end
    puts "}"
  end

  desc "Print the structure of a document's links in Graphviz dot format"
  task :links, [:content_id] => :environment do |_, args|
    d = Document.find_by!(content_id: args.fetch(:content_id))
    e = d.editions.live.last
    content_store_payload = DownstreamPayload.new(e, 0).content_store_payload


    puts "digraph {"
    content_id = content_store_payload.fetch(:content_id)
    label = content_store_payload[:title]
    label = content_store_payload[:base_path] if label.blank?
    label = content_id if label.blank?
    parent = content_id
    puts "\"#{parent}\" [label=\"#{label}\"]"
    nodes = Set.new
    content_store_payload.fetch(:expanded_links).each do |(key, links)|
      print_links_graphviz("root", nodes, parent, key, links)
    end
    puts "}"
  end
end
