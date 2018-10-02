# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /v2/links/changes', type: :request do
  before :each do
    stub_request(:put, /^#{Plek.find('draft-content-store')}.*$/)
  end

  scenario 'Get a link change' do
    editions = create_list(:edition, 2)
    user_uid = SecureRandom.uuid

    make_patch_links_request(
      editions.first.content_id,
      { taxons: [editions.second.content_id] },
      user_uid: user_uid
    )

    get '/v2/links/changes', params: { link_types: %w[taxons] }

    expect(parsed_response.deep_symbolize_keys)
      .to match(link_changes: [{
                                 source: { title: editions.first.title,
                                           base_path: editions.first.base_path,
                                           content_id: editions.first.content_id },
                                 target: { title: editions.second.title,
                                           base_path: editions.second.base_path,
                                           content_id: editions.second.content_id },
                                 link_type: 'taxons',
                                 change: 'add',
                                 user_uid: user_uid,
                                 created_at: be_a(String)
                               }])
  end

  scenario 'User filters by link_type' do
    make_patch_links_request(
      SecureRandom.uuid,
      taxons: [SecureRandom.uuid]
    )

    make_patch_links_request(
      SecureRandom.uuid,
      organisations: [SecureRandom.uuid]
    )

    make_patch_links_request(
      SecureRandom.uuid,
      something_else: [SecureRandom.uuid]
    )

    get '/v2/links/changes', params: { link_types: %w[taxons organisations] }

    expect(number_of_results).to eql(2)
  end

  scenario 'User filters by source' do
    source_uuids = Array.new(2) { SecureRandom.uuid }
    source_uuids.each do |uuid|
      make_patch_links_request(
        uuid,
        taxons: [SecureRandom.uuid]
      )
    end

    make_patch_links_request(
      SecureRandom.uuid,
      taxons: [SecureRandom.uuid]
    )

    get '/v2/links/changes', params: { link_types: %w[taxons], source_content_ids: source_uuids }

    expect(number_of_results).to eql(2)
  end

  scenario 'User filters by target' do
    target_uuids = Array.new(2) { SecureRandom.uuid }
    target_uuids.each do |uuid|
      make_patch_links_request(
        SecureRandom.uuid,
        taxons: [uuid]
      )
    end

    make_patch_links_request(
      SecureRandom.uuid,
      taxons: [SecureRandom.uuid]
    )

    get '/v2/links/changes', params: { link_types: 'taxons', target_content_ids: target_uuids }

    expect(number_of_results).to eql(2)
  end

  scenario 'User filters by users' do
    user_uuids = Array.new(2) { SecureRandom.uuid }
    user_uuids.each do |uuid|
      make_patch_links_request(
        SecureRandom.uuid,
        { taxons: [SecureRandom.uuid] },
        user_uid: uuid
      )
    end

    make_patch_links_request(
      SecureRandom.uuid,
      { taxons: [SecureRandom.uuid] },
      user_uid: SecureRandom.uuid
    )

    get '/v2/links/changes', params: {
      link_types: %w[taxons],
      users: user_uuids
    }

    expect(number_of_results).to eql(2)
  end

  def make_patch_links_request(content_id, links, params = {})
    patch "/v2/links/#{content_id}",
          params: { links: links }.to_json,
          headers: { 'X-GOVUK-AUTHENTICATED-USER' => params[:user_uid] }
  end

  def number_of_results
    parsed_response['link_changes'].size
  end
end
