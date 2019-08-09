# Usage:
#
# expect(file).to be a_gzipped_file
# expect(file).to be a_gzipped_file.containing("Hello World")
# expect(class).to receive(:method).with(a_gzipped_file)
RSpec::Matchers.define :a_gzipped_file do
  match do |actual|
    begin
      @file = Zlib::GzipReader.open(actual)
      return true unless @expected_contents

      values_match?(@expected_contents, @file.read)
    rescue Zlib::GzipFile::Error
      false
    end
  end

  chain :containing do |expected_contents|
    @expected_contents = expected_contents
  end
end
