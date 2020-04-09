require "diffy"
require "hashdiff"

module DataHygiene
  class GovspeakCompare
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def published_html
      @published_html ||= format_published_html
    end

    def generated_html
      @generated_html ||= html_from_details(
        Presenters::DetailsPresenter.new(
          edition.details_for_govspeak_conversion,
          Presenters::ChangeHistoryPresenter.new(edition),
        ).details,
      )
    end

    def diffs
      @diffs ||= calculate_diffs
    end

    def same_html?
      Hashdiff.diff(published_html, generated_html) == []
    end

    def pretty_much_same_html?
      return true if same_html?

      diffs.all? { |_, diff| diff == [] }
    end

  private

    def calculate_diffs
      keys = (published_html.keys + generated_html.keys).uniq.sort
      keys.index_with { |key| html_diff(published_html[key], generated_html[key]) }
    end

    def html_diff(old_html, new_html)
      old_html = apply_old_html_common_changes(old_html)
      diff = Diffy::Diff.new(old_html, new_html, context: 1)

      diff = diff.reject { |s| s.match(/^ /) || s.match(/^(\+|-)$/) }

      diff.reject do |s|
        check = (s[0] == "+" ? "-" : "+") + s[1..-1]
        diff.any? { |elem| basically_match(elem) == basically_match(check) }
      end
    end

    def apply_old_html_common_changes(html)
      return unless html

      # In specialist publisher we have a lot of new lines in inline attachments
      # which causes us trouble as we only allow inline attachments to be on a single line
      regex = %r{<a (rel="external" )?href="https:\/\/assets.digital.cabinet-office.gov.uk\/.*?">((?:.|\n)*?)<\/a>}
      html.gsub(regex) { |inner_content| inner_content.tr("\n", " ") }
    end

    # This method strips out a lot of the common differences that are the result
    # of different versions of govspeak rendering.
    # It was wrote when testing Specialist Publisher documents and may need
    # additional items when comparing editions published from different apps
    def basically_match(elem)
      elem = elem.dup
      # strip span surrounding an inline-attachment as this element
      elem.gsub!(/<span\s+class=\"attachment\-inline\">(.+?)<\/span>/, '\1')
      # a number of past inline attachments are incorrectly marked as rel="external"
      # the last p element in a blockquote is given a class of last-child
      elem.gsub!(/(rel="external"|class="last-child")/, "")
      # it's very common for extra whitespace to be present.
      elem.gsub!(/\s+/, "") #whitespace
    end

    def format_published_html
      html_details = html_from_details(edition.details)
      html_details.transform_values do |value|
        # pushed through nokogiri to catch minor html differences (<br /> -> <br>, unicode characters)
        Nokogiri::HTML.fragment(value).to_html
      end
    end

    def html_from_details(details)
      details.each_with_object({}) do |(key, value), memo|
        wrapped = Array.wrap(value)
        html = wrapped.find do |item|
          item.is_a?(Hash) && item[:content_type] == "text/html"
        end
        memo[key] = html[:content] if html && html[:content]
      end
    end
  end
end
