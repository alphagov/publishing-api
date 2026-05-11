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

  describe "#old_digest_retry_set_data" do
    subject { test_class_instance.old_digest_retry_set_data(digest) }

    let(:example_retry_set_entry_item) do
      {
        "retry" => true,
        "queue" => "downstream_low",
        "lock" => "until_executing",
        "lock_args_method" => "uniq_args",
        "on_conflict" => "log",
        "class" => "DownstreamDraftJob",
        "args" => [
          {
            "content_id" => "5f4cdd5a-7631-11e4-a3cb-005056011aef",
            "locale" => "en",
            "update_dependencies" => false,
            "dependency_resolution_source_content_id" => "16628142-57b2-4611-bc03-5912785acee3",
            "source_command" => "put_content",
            "source_fields" => %w[details],
          },
        ],
        "jid" => "d483be7120625851f37531d6",
        "created_at" => 1_777_543_662.566768,
        "traceparent" => "blah",
        "baggage" => "sentry data",
        "trace_propagation_headers" => {
          "sentry-trace" => "an ID",
          "baggage" => "sentry data",
        },
        "lock_timeout" => 0,
        "lock_ttl" => 3600,
        "lock_prefix" => "uniquejobs",
        "lock_args" => [
          "5f4cdd5a-7631-11e4-a3cb-005056011aef",
          "en",
          false,
          [],
          "DownstreamDraftJob",
        ],
        "lock_digest" => digest,
        "enqueued_at" => 1_778_116_697.653957,
        "error_message" => "Can't send unpublished item to draft content store, as there is a draft occupying the same base path",
        "error_class" => "DownstreamDraftExistsError",
        "failed_at" => 1_777_545_167.352332,
        "retry_count" => 20,
        "retried_at" => 1_778_116_697.778639,
      }
    end
    let(:example_retry_set_entry_score) { 1_778_116_697.101102 }
    let(:retry_set_entries) do
      [
        instance_double(
          Sidekiq::SortedEntry,
          item: example_retry_set_entry_item,
          score: example_retry_set_entry_score,
        ),
      ]
    end

    before do
      allow(Sidekiq::RetrySet)
        .to receive(:new)
        .and_return(instance_double(
                      Sidekiq::RetrySet,
                      entries: retry_set_entries,
                    ))
    end

    it "returns an array of hashes with retry set data for the given digest" do
      expect(subject).to match_array(
        [
          {
            retries_param: "1778116697.101102-d483be7120625851f37531d6",
            jid: "d483be7120625851f37531d6",
            created_at: "2026-04-30 10:07:42 UTC",
            failed_at: "2026-04-30 10:32:47 UTC",
            enqueued_at: "2026-05-07 01:18:17 UTC",
            retried_at: "2026-05-07 01:18:17 UTC",
            retry_count: 20,
            queue: "downstream_low",
            class: "DownstreamDraftJob",
            lock_args: <<~LOCK_ARGS.chomp,
              [
                "5f4cdd5a-7631-11e4-a3cb-005056011aef",
                "en",
                false,
                [],
                "DownstreamDraftJob"
              ]
            LOCK_ARGS
            args: <<~ARGS.chomp,
              [
                {
                  "content_id": "5f4cdd5a-7631-11e4-a3cb-005056011aef",
                  "locale": "en",
                  "update_dependencies": false,
                  "dependency_resolution_source_content_id": "16628142-57b2-4611-bc03-5912785acee3",
                  "source_command": "put_content",
                  "source_fields": [
                    "details"
                  ]
                }
              ]
            ARGS
            lock_ttl: 3600,
            error_class: "DownstreamDraftExistsError",
            error_message: "Can't send unpublished item to draft content store, as there is a draft occupying the same base path",
          },
        ],
      )
    end

    it "includes only a subset of fields from retry set entries" do
      expect(subject.first.keys).to include(*%i[
        args
        class
        created_at
        enqueued_at
        error_class
        error_message
        failed_at
        jid
        lock_args
        lock_ttl
        queue
        retried_at
        retry_count
      ])

      expect(subject.first.keys).not_to include(*%i[
        lock
        lock_args_method
        lock_digest
        lock_prefix
        lock_timeout
        on_conflict
        retry
        trace_propagation_headers
        traceparent
      ])
    end

    it "includes a field for linking to the related entry in the retries tab" do
      retries_param = subject.first[:retries_param]

      expect(retries_param).to match(/#{example_retry_set_entry_score}/)
      expect(retries_param).to match(/#{example_retry_set_entry_item['jid']}/)
      expect(retries_param).to eq("1778116697.101102-d483be7120625851f37531d6")
    end

    it "orders the fields in a sensible way" do
      expect(subject.first.keys).to eq(%i[
        retries_param
        jid
        created_at
        failed_at
        enqueued_at
        retried_at
        retry_count
        queue
        class
        lock_args
        args
        lock_ttl
        error_class
        error_message
      ])
    end

    it "uses a human-readable date format" do
      expect(
        subject.first.slice(*%i[created_at failed_at enqueued_at retried_at]),
      ).to eq(
        {
          created_at: "2026-04-30 10:07:42 UTC",
          failed_at: "2026-04-30 10:32:47 UTC",
          enqueued_at: "2026-05-07 01:18:17 UTC",
          retried_at: "2026-05-07 01:18:17 UTC",
        },
      )
    end

    context "when there are multiple retry set entries for the given digest" do
      let(:retry_set_entries) do
        [
          instance_double(
            Sidekiq::SortedEntry,
            item: example_retry_set_entry_item,
            score: example_retry_set_entry_score,
          ),
          instance_double(
            Sidekiq::SortedEntry,
            item: example_retry_set_entry_item,
            score: example_retry_set_entry_score + 10,
          ),
          instance_double(
            Sidekiq::SortedEntry,
            item: {
              **example_retry_set_entry_item,
              "jid" => "7078792606ac550943217ct3",
              "class" => "DownstreamLiveJob",
            },
            score: example_retry_set_entry_score,
          ),
        ]
      end

      it "includes all of them" do
        expect(subject.size).to eq(3)
      end
    end

    context "when there are retry set entries for other digests" do
      let(:retry_set_entries) do
        [
          instance_double(
            Sidekiq::SortedEntry,
            item: {
              **example_retry_set_entry_item,
              "class" => "ClassForExpectedEntry",
            },
            score: example_retry_set_entry_score,
          ),
          instance_double(
            Sidekiq::SortedEntry,
            item: {
              **example_retry_set_entry_item,
              "class" => "ClassForUnexpectedEntry",
              "lock_digest" => "uniquejobs:3a605fc8bbfeba49ab3cc7a94d37b8ca",
            },
            score: example_retry_set_entry_score,
          ),
        ]
      end

      it "excludes them" do
        expect(subject.size).to eq(1)
        expect(subject.first[:class]).to eq("ClassForExpectedEntry")
      end
    end
  end
end
