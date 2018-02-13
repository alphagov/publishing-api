require "rails_helper"
require 'live_content_report_exporter'

RSpec.describe LiveContentReportExporter do
  let!(:live_publisher_edition) { create(:live_edition, phase: 'live', base_path: '/foo', publishing_app: 'publisher', first_published_at: 2.days.ago) }
  let!(:live_smartanswers_edition) { create(:live_edition, phase: 'live', base_path: '/bar', publishing_app: 'smartanswers', first_published_at: 1.day.ago) }
  let!(:draft_publisher_edition) { create(:edition, phase: 'live', base_path: '/baz', publishing_app: 'publisher', first_published_at: 3.days.ago) }
  let!(:live_other_publisher_edition) { create(:live_edition, phase: 'live', base_path: '/qux', publishing_app: 'other-publisher', first_published_at: 4.days.ago) }
  let!(:live_publisher_redirect) { create(:redirect_live_edition, phase: 'live', publishing_app: 'publisher') }
  let!(:live_publisher_gone) { create(:gone_live_edition, phase: 'live', publishing_app: 'publisher') }
  let!(:beta_publisher_edition) { create(:live_edition, phase: 'beta', base_path: '/garply', publishing_app: 'publisher', first_published_at: 5.days.ago) }

  describe '#total' do
    it 'is the count of live editions belonging to the supplied publishing apps' do
      expect(described_class.new(%w(publisher smartanswers)).total).to eq 2
      expect(described_class.new(%w(publisher)).total).to eq 1
    end
  end

  describe '#file_path' do
    subject { described_class.new(%w(publisher other-publisher)).file_path.to_s }

    it 'inculdes the names of the publishing apps' do
      expect(subject).to match(/publisher_other-publisher/)
    end

    it 'is a CSV file' do
      expect(subject).to match(/\.csv\Z/)
    end

    it 'contains the current time' do
      time = Time.zone.now
      Timecop.freeze(time) do
        expect(subject).to match(/#{time.strftime('%Y%m%d%H%M%S%N')}/)
      end
    end

    it 'lives in the rails root' do
      expect(subject).to match(/\A#{Rails.root}/)
    end
  end

  describe 'export' do
    subject { described_class.new(%w(publisher smartanswers)) }

    after { File.unlink(subject.file_path) if File.exist? subject.file_path }

    it 'writes a header row to the csv' do
      subject.export

      expect(File.readlines(subject.file_path).first).to eq "URL,Page title,Format,First published at\n"
    end

    it 'writes the url, title, document_type, and first published at of each relevant edition to the csv file' do
      subject.export

      csv = CSV.readlines(File.open(subject.file_path))
      expect(csv.size - 1).to eq 2

      expect(csv).to include [live_publisher_edition.web_url, live_publisher_edition.title, live_publisher_edition.document_type, live_publisher_edition.first_published_at.iso8601]
      expect(csv).to include [live_smartanswers_edition.web_url, live_smartanswers_edition.title, live_smartanswers_edition.document_type, live_smartanswers_edition.first_published_at.iso8601]
    end

    it 'reports progress to the supplied proc, once per relevant edition' do
      progress_spy = spy("progress")
      subject.export(progress: ->(index, count) { progress_spy.progression(index, count) })

      expect(progress_spy).to have_received(:progression).with(0, 2).ordered
      expect(progress_spy).to have_received(:progression).with(1, 2).ordered
      expect(progress_spy).not_to have_received(:progression).with(2, 2)
    end
  end
end
