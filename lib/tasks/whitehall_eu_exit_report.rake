desc "Generate a report of all Whitehall content per organisation."
task :whitehall_eu_exit_report, [:path] => :environment do |_, args|
  WhitehallEuExitReport.call(path: args[:path])
end
