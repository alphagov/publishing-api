require "rails_helper"

RSpec.describe TimedFeature do
  describe ".check!" do
    it "does nothing if the feature hasn't expired" do
      Timecop.freeze "2016-01-01" do
        expect {
          TimedFeature.check!(owner: "Me", expires: "2017-01-01")
        }.not_to raise_error
      end
    end

    it "raises a command error if the feature has expired" do
      Timecop.freeze "2018-01-01" do
        expect {
          TimedFeature.check!(owner: "Me", expires: "2017-01-01")
        }.to raise_error(CommandError)
      end
    end
  end
end
