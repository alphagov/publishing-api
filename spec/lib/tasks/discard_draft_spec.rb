require "rails_helper"

RSpec.describe "Discard draft rake task" do
  before do
    Rake::Task['discard_draft'].reenable
  end

  it "runs the process to discard a draft" do
    payload = { content_id: "content_id" }
    expect(Commands::V2::DiscardDraft).to receive(:call).with(payload)

    Rake::Task['discard_draft'].invoke("content_id")
  end

  it "raises an error if a content id is not provided" do
    expect { Rake::Task['discard_draft'].invoke }.to raise_error('Missing parameter: content_id')
  end
end
