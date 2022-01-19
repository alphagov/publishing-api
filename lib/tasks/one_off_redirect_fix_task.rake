desc "Redirect legacy Whitehall HTML attachment paths"
task update_redirects: :environment do
  OneOffRedirectFixService.fix_redirects!
end
