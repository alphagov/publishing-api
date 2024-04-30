RSpec.describe "CSV report rake tasks" do
  describe "csv_report:word_usages" do
    let(:task) { Rake::Task["csv_report:word_usages"] }
    before { task.reenable }

    it "outputs a CSV of editions which include words in the word list" do
      e1 = create(
        :live_edition,
        details: { some_field: "Yes, we have no BANANA." },
        base_path: "/8QqkrIDeTeA",
        title: "No bananas",
        publishing_app: "fruit_publisher",
        document_type: "fruit",
      )
      e2 = create(
        :live_edition,
        details: { some_field: "Ring ring ring ring banana phone!" },
        base_path: "/shorts/-n77rSzMUX8",
        title: "Banana phone",
        publishing_app: "fruit_publisher",
        document_type: "fruit",
      )
      e3 = create(
        :live_edition,
        details: { some_field: "There's a fruit man on our street, his name is Mr. Peach" },
        base_path: "/dQw4w9WgXcQ",
        title: "Mr. Peach",
        publishing_app: "whitehall",
        document_type: "person",
      )
      # ... and a few editions which won't match:
      create(:live_edition)
      create(:live_edition)
      create(:live_edition)
      create(:live_edition)
      create(:live_edition)

      expect { task.invoke("banana", "peach") }.to output(<<~CSV).to_stdout
        base_path,title,content_id,locale,publishing_app,document_type,words
        /8QqkrIDeTeA,No bananas,#{e1.content_id},#{e1.locale},fruit_publisher,fruit,banana
        /shorts/-n77rSzMUX8,Banana phone,#{e2.content_id},#{e2.locale},fruit_publisher,fruit,banana
        /dQw4w9WgXcQ,Mr. Peach,#{e3.content_id},#{e3.locale},whitehall,person,peach
      CSV
    end
  end

  describe "csv_report:publishings_by_date_range" do
    let(:task) { Rake::Task["csv_report:publishings_by_date_range"] }
    before { task.reenable }

    it "outputs a CSV of editions published between a date range" do
      first_publishing = create(:live_edition,
                                published_at: "2020-01-01 10:00",
                                update_type: "major",
                                user_facing_version: 1)
      minor_update = create(:live_edition,
                            published_at: "2020-01-03 10:00",
                            update_type: "minor",
                            user_facing_version: 2)

      # drafts are ignored
      create(:draft_edition)
      # outside date range
      create(:live_edition, published_at: "2020-01-05")
      # ignored update type
      create(:live_edition, published_at: "2020-01-05", update_type: "republish")

      first_publishing_row = ["2020-01-01 10:00:00 UTC",
                              first_publishing.base_path,
                              first_publishing.content_id,
                              first_publishing.locale,
                              first_publishing.title,
                              first_publishing.document_type,
                              "major",
                              "true"]

      minor_update_row = ["2020-01-03 10:00:00 UTC",
                          minor_update.base_path,
                          minor_update.content_id,
                          minor_update.locale,
                          minor_update.title,
                          minor_update.document_type,
                          "minor",
                          "false"]
      csv = <<~CSV
        published_at,base_path,content_id,locale,title,document_type,update_type,first_publishing
        #{first_publishing_row.join(',')}
        #{minor_update_row.join(',')}
      CSV

      expect { task.invoke("2020-01-01 00:00", "2020-01-04 00:00") }
        .to output(csv).to_stdout
    end
  end

  describe "csv_report:unpublishings_by_date_range" do
    let(:task) { Rake::Task["csv_report:unpublishings_by_date_range"] }
    before { task.reenable }

    it "outputs a CSV of documents published between a date range" do
      redirect_unpublishing = create(:unpublishing,
                                     type: "redirect",
                                     created_at: "2020-01-01 10:00")
      gone_unpublishing = create(:unpublishing,
                                 type: "gone",
                                 created_at: "2020-01-03 10:00")

      # substitutes are ignored
      create(:unpublishing, type: "substitute", created_at: "2020-01-02")
      # outside date range
      create(:unpublishing, type: "gone", created_at: "2020-01-05")

      redirect_edition = redirect_unpublishing.edition
      redirect_unpublishing_row = ["2020-01-01 10:00:00 UTC",
                                   redirect_edition.base_path,
                                   redirect_edition.content_id,
                                   redirect_edition.locale,
                                   redirect_edition.title,
                                   redirect_edition.document_type,
                                   "redirect"]

      gone_edition = gone_unpublishing.edition
      gone_unpublishing_row = ["2020-01-03 10:00:00 UTC",
                               gone_edition.base_path,
                               gone_edition.content_id,
                               gone_edition.locale,
                               gone_edition.title,
                               gone_edition.document_type,
                               "gone"]
      csv = <<~CSV
        unpublished_at,base_path,content_id,locale,title,document_type,unpublishing_type
        #{redirect_unpublishing_row.join(',')}
        #{gone_unpublishing_row.join(',')}
      CSV

      expect { task.invoke("2020-01-01 00:00", "2020-01-04 00:00") }
        .to output(csv).to_stdout
    end
  end
end
