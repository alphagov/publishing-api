class TestClass
  include SidekiqOldLocks::Web::Helpers
end

RSpec.describe SidekiqOldLocks::Web::Helpers do
  let(:test_class_instance) { TestClass.new }
  let(:digest) { "uniquejobs:f2f8d140b3191770c992ad238c95dbb9" }

  describe "#old_digests" do
    let(:digest_entries) { { digest => "1778154689.8511593" } }
    let(:mock_reaper) { instance_double(SidekiqUniqueJobs::Orphans::RubyReaper) }

    before do
      allow(SidekiqUniqueJobs::Digests)
        .to receive(:new)
        .and_return(instance_double(
                      SidekiqUniqueJobs::Digests,
                      entries: digest_entries,
                    ))
      allow(SidekiqUniqueJobs::Orphans::RubyReaper)
        .to receive(:new)
        .and_return(mock_reaper)
    end

    subject { test_class_instance.old_digests }

    it "returns an array of hashes with basic lock digest information" do
      allow(mock_reaper).to receive(:active?).and_return(true)

      expect(subject).to match_array(
        [{ digest:, created_at: 1_778_154_689.8511593, state: :active }],
      )
    end

    context "when the digest has existed for at least the default TTL" do
      let(:digest_entries) { { digest => (Time.zone.now - 3600.seconds).to_f.to_s } }

      before do
        allow(SidekiqUniqueJobs)
          .to receive_message_chain(:config, :lock_ttl)
          .and_return(3600)
        allow(mock_reaper).to receive(:active?).and_return(true)
      end

      it "includes the digest" do
        expect(subject).not_to be_empty
      end
    end

    context "when the digest has existed for less than the default TTL" do
      let(:digest_entries) { { digest => Time.zone.now.to_f.to_s } }

      before do
        allow(SidekiqUniqueJobs)
          .to receive_message_chain(:config, :lock_ttl)
          .and_return(3600)
      end

      it "ignores the digest" do
        expect(subject).to be_empty
      end
    end

    context "with an active digest" do
      before { allow(mock_reaper).to receive(:active?).and_return(true) }

      it "includes accurate state information" do
        expect(subject).to match_array([hash_including(state: :active)])
      end
    end

    context "with an enqueued digest" do
      before do
        allow(mock_reaper).to receive_messages(active?: false, enqueued?: true)
      end

      it "includes accurate state information" do
        expect(subject).to match_array([hash_including(state: :enqueued)])
      end
    end

    context "with a retried digest" do
      before do
        allow(mock_reaper).to receive_messages(
          active?: false,
          enqueued?: false,
          retried?: true,
        )
      end

      it "includes accurate state information" do
        expect(subject).to match_array([hash_including(state: :retried)])
      end
    end

    context "with a scheduled digest" do
      before do
        allow(mock_reaper).to receive_messages(
          active?: false,
          enqueued?: false,
          retried?: false,
          scheduled?: true,
        )
      end

      it "includes accurate state information" do
        expect(subject).to match_array([hash_including(state: :scheduled)])
      end
    end

    context "with multiple old digests" do
      let(:digest_entries) do
        {
          digest => "1778154689.8511593",
          "uniquejobs:3a605fc8bbfeba49ab3cc7a94d37b8ca" => "1778136727.1882838",
          "uniquejobs:89d09fafa861031d4882a7499e12b171" => "1778116239.961951",
          "uniquejobs:e8a6a3befa0ee0edf2096d3d94adb5f9" => "1778168687.9721427",
        }
      end

      before { allow(mock_reaper).to receive(:active?).and_return(true) }

      it "sorts the digest hashes by created time, newest first" do
        expect(subject).to match_array([
          hash_including(created_at: 1_778_168_687.9721427),
          hash_including(created_at: 1_778_154_689.8511593),
          hash_including(created_at: 1_778_136_727.1882838),
          hash_including(created_at: 1_778_116_239.961951),
        ])
      end
    end
  end
end
