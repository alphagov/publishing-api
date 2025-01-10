RSpec.describe "Add document type to events Rake task" do
  let(:task) { Rake::Task["add_document_type_to_host_content_update_events"] }
  before { task.reenable }

  it "adds the document types to the events payload" do
    editions = [
      create(:edition, state: "published", document_type: "content_type_1"),
      create(:edition, state: "published", document_type: "content_type_2"),
      create(:edition, state: "published", document_type: "content_type_3"),
    ]

    events = [
      create(:event, action: "HostContentUpdateJob", payload: { source_block: { content_id: editions[0].document.content_id } }),
      create(:event, action: "HostContentUpdateJob", payload: { source_block: { content_id: editions[1].document.content_id } }),
      create(:event, action: "HostContentUpdateJob", payload: { source_block: { content_id: editions[2].document.content_id } }),
    ]

    event_without_content_id = create(:event, action: "HostContentUpdateJob", payload: { something: "else" })
    other_event = create(:event, action: "SomeOtherAction", payload: { source_block: { content_id: editions[2].document.content_id } })

    task.invoke

    events.each_with_index do |e, i|
      expect(e.reload.payload).to eq({
        source_block: {
          content_id: editions[i].document.content_id,
          document_type: editions[i].document_type,
        },
      })
    end

    expect(event_without_content_id.reload.payload).to eq({ something: "else" })
    expect(other_event.reload.payload).to eq({ source_block: { content_id: editions[2].document.content_id } })
  end
end
