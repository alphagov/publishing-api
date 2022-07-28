require "action_view/helpers/tag_helper"

module Presenters
  class DebugPresenter
    include ActionView::Helpers::TagHelper
    attr_accessor :output_buffer
    attr_reader :content_id

    def initialize(content_id)
      @content_id = content_id
    end

    def editions
      @editions ||= Edition.with_document.where("documents.content_id": content_id)
    end

    def user_facing_versions
      editions.map(&:user_facing_version).sort.reverse
    end

    def latest_editions
      @latest_editions ||= ::Queries::GetLatest.call(editions)
    end

    def latest_state_with_locale
      latest_editions.map { |ci| [ci.document.locale, ci.state] }
    end

    def link_set
      @link_set ||= LinkSet.find_by(content_id:)
    end

    def expanded_links
      links = ::Queries::GetExpandedLinks.call(content_id, "en")
      rows = []
      rows << [links[:content_id], "", "current"]
      links[:expanded_links].each do |type, sub_links|
        rows << [type, links[:content_id], "current"]
        sub_links.each do |link|
          rows << [
            {
              v: (link[:content_id].to_s + type.to_s),
              f: "<a href='/debug/#{link[:content_id]}'>#{link[:content_id]}</a>",
            },
            type,
            "",
          ]
        end
      end

      rows
    end

    def states
      grouped_editions = editions.group_by { |e| e.document.locale }
      grouped_editions.each_with_object([]) do |(locale, editions), states|
        states << [locale, ""]
        states << [{ v: editions.first.id.to_s, f: editions.first.state }, locale]
        editions[1..].each_with_index do |edition, index|
          states << [{ v: edition.id.to_s, f: edition.state }, editions[index].try(:id).to_s]
        end
      end
    end

    def event_timeline
      events.map do |event|
        [event.action, "", event.id.to_s, event.created_at, event.created_at + 1.second]
      end
    end

    def presented_edition
      @presented_edition ||= Edition.find(latest_editions.last.id)
    end

    delegate :web_url, to: :presented_edition

    delegate :title, to: :presented_edition

    delegate :api_url, to: :presented_edition

    def events
      Event.where(content_id:).order(:created_at)
    end

    def event_presenter(event_attributes)
      table_for(event_attributes)
    end

    def table_for(hash, klass = "")
      tag.table class: "table key-value-table #{klass}" do
        rows = hash.map do |k, v|
          tag.tr do
            tag.td(k) + tag.td(display_value(v))
          end
        end

        rows.join.html_safe
      end
    end

    def display_value(value)
      if value.is_a?(Hash)
        tag.pre do
          JSON.pretty_generate(value)
        end
      elsif v.blank?
        "<em>empty</em>".html_safe
      else
        v
      end
    end
  end
end
