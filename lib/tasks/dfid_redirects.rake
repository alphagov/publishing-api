require "csv"

desc "Find DFID research report redirects"
task dfid_redirects: :environment do
  dfid_redirects = Edition
    .where(document_type: "redirect")
    .where("base_path LIKE :prefix", prefix: "/dfid-research-outputs/%")

  csv_out = CSV.new($stdout)

  dfid_redirects.each do |i|
    csv_out << [i.base_path]
  end
end
