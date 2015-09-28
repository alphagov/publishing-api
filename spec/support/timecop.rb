
RSpec.configuration.after :each do
  Timecop.return
end
