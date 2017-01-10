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
      @content_items ||= Edition.where(content_id: content_id)
    end

    def user_facing_versions
      content_items.map(&:user_facing_version).sort.reverse
    end

    def latest_content_items
      @latest_content_items ||= ::Queries::GetLatest.call(content_items)
    end

    def latest_state_with_locale
      latest_content_items.map { |ci| [ci.locale, ci.state] }
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
      content_items.group_by(&:locale).each_with_object([]) do |(locale, content_items), states|
        states << [locale, '']
        states << [{ v: content_items.first.id.to_s, f: content_items.first.state }, locale]
        content_items[1..-1].each_with_index do |content_item, index|
          states << [{ v: content_item.id.to_s, f: content_item.state }, content_items[index].try(:id).to_s]
        end
      end
    end

    def event_timeline
      events.map do |event|
        [event.action, '', event.id.to_s, event.created_at, event.created_at + 1.second]
      end
    end

    def web_content_item
      @web_content_item ||= ::Queries::GetWebEditions.find(
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
