require "rails_helper"

RSpec.describe "Special route rake namespace" do
  describe "draft task" do
    before do
      Rake::Task['special_route:draft'].reenable
      # suppress output
      allow($stdout).to receive(:puts)
      allow_any_instance_of(Object).to receive(:pp)
    end

    let(:content_id) { SecureRandom.uuid }

    it "runs the command to put content an edition" do
      payload = a_hash_including(
        base_path: "/test",
        title: "Test",
        rendering_app: "government-frontend",
        routes: [{ path: "/test", type: "prefix" }],
      )
      expect(Commands::V2::PutContent).to receive(:call).with(payload)

      Rake::Task['special_route:draft'].invoke("/test", "Test", "government-frontend")
    end

    it "can accept a route_type argument" do
      payload = a_hash_including(
        routes: [{ path: "/test", type: "exact" }],
      )
      expect(Commands::V2::PutContent).to receive(:call).with(payload)

      Rake::Task['special_route:draft'].invoke("/test", "Test", "government-frontend", "exact")
    end

    it "can handle a command error" do
      expect(Commands::V2::PutContent).to receive(:call)
        .and_raise(CommandError.new(code: 422, message: "Test"))

      expect { Rake::Task['special_route:draft'].invoke("/test", "Test", "government-frontend") }
        .to raise_error(SystemExit)
    end

    it "raises an error if a base_path is not provided" do
      expect { Rake::Task['special_route:draft'].invoke }.to raise_error(KeyError)
    end

    it "raises an error if a title is not provided" do
      expect { Rake::Task['special_route:draft'].invoke("/test") }.to raise_error(KeyError)
    end

    it "raises an error if a rendering_app is not provided" do
      expect { Rake::Task['special_route:draft'].invoke("/test", "Title") }.to raise_error(KeyError)
    end
  end
end
