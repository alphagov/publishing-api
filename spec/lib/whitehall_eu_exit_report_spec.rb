require "rails_helper"

RSpec.describe WhitehallEuExitReport do
  let(:path) { Dir.mktmpdir }
  subject { described_class.call(path: path) }

  before { subject }

  it "it should create a folder" do
    expect(File).to exist(path)
  end
end
