require 'rails_helper'

RSpec.describe 'Dependency Resolution' do
  let(:draft_content_store_base) { Plek.find('draft-content-store') }

  context 'with two drafts' do
    def draft_payload(
          base_path,
          content_id: SecureRandom.uuid,
          locale: 'en',
          title: 'Some title'
        )
      {
        content_id: content_id,
        base_path: base_path,
        update_type: 'major',
        title: title,
        publishing_app: 'publisher',
        rendering_app: 'frontend',
        document_type: 'guide',
        schema_name: 'guide',
        locale: locale,
        routes: [{ path: base_path, type: 'exact' }],
        redirects: [],
        phase: 'beta',
        change_note: { note: 'Info', public_timestamp: Time.now.utc.to_s }
      }
    end

    let(:draft_1_content_id) { SecureRandom.uuid }
    let(:draft_2_content_id) { SecureRandom.uuid }

    let(:draft_1_base_path) { '/draft1' }
    let(:draft_2_base_path) { '/draft2' }

    before do
      [draft_1_base_path, draft_2_base_path].each do |base_path|
        stub_request(
          :put,
          Plek.find('draft-content-store') + "/content#{base_path}"
        )
      end
    end

    context 'when a test link is already present' do
      before do
        Commands::V2::PatchLinkSet.call(
          content_id: draft_2_content_id,
          links: {
            test_link_type: [
              draft_1_content_id
            ]
          }
        )
      end

      it 'the link is presented to the content store when the target becomes available' do
        Commands::V2::PutContent.call(
          draft_payload(
            draft_2_base_path,
            content_id: draft_2_content_id
          )
        )
        expect(WebMock).to have_requested(
          :put,
          "#{draft_content_store_base}/content#{draft_2_base_path}"
        ).with(
          body: hash_including(
            'expanded_links' => hash_excluding('test_link_type')
          )
        ).once

        Commands::V2::PutContent.call(
          draft_payload(
            draft_1_base_path,
            content_id: draft_1_content_id
          )
        )
        expect(WebMock).to have_requested(
          :put,
          "#{draft_content_store_base}/content#{draft_2_base_path}"
        ).with(
          body: hash_including(
            'expanded_links' => hash_including('test_link_type')
          )
        ).once
      end
    end

    context 'when updating an existing draft' do
      let(:draft_1_first_title) { 'First Title' }
      let(:draft_1_second_title) { 'Second Title' }

      before do
        stub_request(
          :put,
          "#{draft_content_store_base}/content#{draft_1_base_path}"
        )

        Commands::V2::PatchLinkSet.call(
          content_id: draft_2_content_id,
          links: {
            test_link_type: [
              draft_1_content_id
            ]
          }
        )

        Commands::V2::PutContent.call(
          draft_payload(
            draft_1_base_path,
            content_id: draft_1_content_id,
            title: draft_1_first_title
          )
        )
      end

      it 'dependency resolution correctly updates the title in the expanded_links' do
        Commands::V2::PutContent.call(
          draft_payload(
            draft_2_base_path,
            content_id: draft_2_content_id
          )
        )

        expect(WebMock).to have_requested(
          :put,
          "#{draft_content_store_base}/content#{draft_2_base_path}"
        ).with(
          body: hash_including(
            'expanded_links' => hash_including(
              'test_link_type' => contain_exactly(
                hash_including(
                  'title' => draft_1_first_title
                )
              )
            )
          )
        ).once

        Commands::V2::PutContent.call(
          draft_payload(
            draft_1_base_path,
            content_id: draft_1_content_id,
            title: draft_1_second_title
          )
        )

        expect(WebMock).to have_requested(
          :put,
          "#{draft_content_store_base}/content#{draft_2_base_path}"
        ).with(
          body: hash_including(
            'expanded_links' => hash_including(
              'test_link_type' => contain_exactly(
                hash_including(
                  'title' => draft_1_second_title
                )
              )
            )
          )
        ).once
      end
    end
  end
end
