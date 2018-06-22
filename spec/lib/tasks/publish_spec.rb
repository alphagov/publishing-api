require "rails_helper"

RSpec.describe "Publish rake task" do
  before do
    Rake::Task['publish'].reenable
    # suppress puts output
    allow($stdout).to receive(:puts)
    allow_any_instance_of(Object).to receive(:pp)
  end

  let(:content_id) { SecureRandom.uuid }

  it "runs the command to publish an edition" do
    payload = { content_id: content_id, locale: "en" }
    expect(Commands::V2::Publish).to receive(:call).with(payload)

    Rake::Task['publish'].invoke(content_id)
  end

  it "can accept a locale argument" do
    payload = { content_id: content_id, locale: "fr" }
    expect(Commands::V2::Publish).to receive(:call).with(payload)

    Rake::Task['publish'].invoke(content_id, "fr")
  end

  it "can handle a command error" do
    expect(Commands::V2::Publish).to receive(:call)
      .and_raise(CommandError.new(code: 422, message: "Test"))

    expect { Rake::Task['publish'].invoke(content_id, "en") }
      .to raise_error(SystemExit)
  end

  it "raises an error if a content id is not provided" do
    expect { Rake::Task['publish'].invoke }.to raise_error(KeyError)
  end
end
