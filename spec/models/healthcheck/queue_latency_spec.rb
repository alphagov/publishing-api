require "rails_helper"

RSpec.describe Healthcheck::QueueLatency do
  describe "QUEUES" do
    it "contains string keys" do
      Healthcheck::QueueLatency::QUEUES.each_key do |key|
        expect(key).to be_a String
      end
    end

    it "has valid values" do
      Healthcheck::QueueLatency::QUEUES.each_value do |value|
        expect(value[:warning]).to be_a(Integer)
        expect(value[:critical]).to be_a(Integer)
      end
    end
  end

  it "handles unknown queues without alerting" do
    high_latency = 999
    expect(high_latency < subject.critical_threshold(queue: "that_doesnt_exist"))
  end
end
