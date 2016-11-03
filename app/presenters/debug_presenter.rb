require 'action_view/helpers/tag_helper'

module Presenters
  class DebugPresenter
    include ActionView::Helpers::TagHelper
    attr_accessor :output_buffer
    attr_reader :content_id

    def initialize(content_id)
      @content_id = content_id
    end

    def content_items
      @content_items ||= ContentItem.where(content_id: content_id)
    end

    def user_facing_versions
      UserFacingVersion.join_content_items(content_items).pluck("user_facing_versions.number")
    end

    def locales
      State.join_content_items(
        Translation
        .join_content_items(content_items))
        .select("locale, content_items.id as id, states.name as state")
    end

    def latest_content_items
      ::Queries::GetLatest.call(content_items)
    end

    def latest_state_with_locale
      Translation.join_content_items(State.join_content_items(latest_content_items)).pluck("translations.locale, states.name")
    end

    def link_set
      @link_set ||= LinkSet.find_by(content_id: content_id)
    end

    def expanded_links
      links = ::Queries::GetExpandedLinks.call(content_id, "en")
      rows = []
      rows << [links[:content_id], '', 'current']
      links[:expanded_links].each do |type, sub_links|
        rows << [type, links[:content_id], 'current']
        sub_links.each do |link|
          rows << [
            {
              v: (link[:content_id].to_s + type.to_s),
              f: "<a href='/debug/#{link[:content_id]}'>#{link[:content_id]}</a>"
            },
            type,
            ''
          ]
        end
      end

      rows
    end

    def states
      @states = []
      locales.group_by(&:locale).each do |locale, local_states|
        @states << [locale, '']
        @states << [{ v: local_states.first.id.to_s, f: local_states.first.state }, locale]
        local_states[1..-1].each_with_index do |state, index|
          @states << [{ v: state.id.to_s, f: state.state }, local_states[(index + 1) - 1].try(:id).to_s]
        end
      end
      @states
    end

    def event_timeline
      events.map do |event|
        [event.action, '', event.id.to_s, event.created_at, event.created_at + 1.second]
      end
    end

    def web_content_item
      ::Queries::GetWebContentItems.find(
        latest_content_items.last.id
      )
    end

    def web_url
      web_content_item.web_url
    end

    def title
      web_content_item.title
    end

    def api_url
      web_content_item.api_url
    end

    def events
      Event.where(content_id: content_id).order(:created_at)
    end

    def event_presenter(event_attributes)
      table_for(event_attributes)
    end

    def table_for(hash, klass = '')
      content_tag :table, class: "table key-value-table #{klass}" do
        rows = hash.map do |k, v|
          content_tag :tr do
            content_tag(:td, k) + content_tag(:td, display_value(v))
          end
        end

        rows.join.html_safe
      end
    end

    def display_value(v)
      if v.is_a?(Hash)
        content_tag :pre do
          JSON.pretty_generate(v)
        end
      elsif v.blank?
        "<em>empty</em>".html_safe
      else
        v
      end
    end
  end
end
