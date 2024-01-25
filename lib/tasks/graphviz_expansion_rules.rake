namespace :graphviz_expansion_rules do
  task :dot, [] => :environment do
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
end
