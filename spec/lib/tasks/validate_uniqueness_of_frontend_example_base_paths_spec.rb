require "spec_helper"
require "json"
require "rake"

RSpec.describe "validate uniqueness rake task" do
  before do
    task.reenable
  end

  def generate_example(name, base_path)
    example_path = tmpdir + name
    File.write(example_path, JSON.dump("base_path" => base_path))
    example_path
  end

  let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

  after(:each) { FileUtils.remove_entry_secure(tmpdir) }

  context "validate_uniqueness_of_frontend_example_base_paths" do
    let(:task) { Rake::Task["validate_uniqueness_of_frontend_example_base_paths"] }

    context "all examples have unique base_paths" do
      let(:examples) do
        [
          generate_example("a.json", "/letter_a"),
          generate_example("b.json", "/letter_b"),
        ]
      end

      it "succeeds without exceptions" do
        expect { task.invoke(examples) }.to_not raise_error
      end
    end

    context "some examples have duplicate base_paths" do
      let(:examples) do
        [
          generate_example("a.json", "/letter_a"),
          generate_example("b.json", "/letter_a"),
        ]
      end

      it "exits with non-zero exit status and outputs a list of the duplicates" do
        expect { task.invoke(examples) }.to raise_error(SystemExit)
          .and output(/a.json.*b.json/m).to_stderr
      end
    end
  end
end
