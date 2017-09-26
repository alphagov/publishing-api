require_dependency "document"
require_dependency "edition"
require_dependency "action"
require_dependency "event"

class Tasks::SplitDates::PopulateDocument
  def initialize(document)
    @document = document
    @editions_data = document
      .editions
      .order(user_facing_version: :asc)
      .select(
        :id,
        :user_facing_version,
        :state,
        :created_at,
        :update_type,
        :first_published_at,
        :temporary_first_published_at,
        :publisher_first_published_at,
        :public_updated_at,
        :major_published_at,
        :publisher_major_published_at,
        :published_at,
        :publisher_published_at,
        :last_edited_at,
        :temporary_last_edited_at,
        :publisher_last_edited_at
      )
      .as_json
  end

  def call
    to_update = Hash[editions_data.map { |e| [e["id"], {}] }]

    populate_first_published_at(to_update)
    populate_published_at(to_update)
    populate_major_published_at(to_update)
    populate_last_edited_at(to_update)

    to_update.each do |id, data|
      compacted = data.compact
      next if compacted.empty?
      Edition.where(id: id).update_all(compacted)
    end
  end

private

  attr_reader :document, :editions_data

  def populate_first_published_at(to_update)
    editions_data.each do |e|
      row = to_update[e["id"]]

      if e["temporary_first_published_at"] != first_published_at
        row["temporary_first_published_at"] = first_published_at
      end

      if !within_1_sec(e["first_published_at"], first_published_at) &&
          e["publisher_first_published_at"] != e["first_published_at"]
        row["publisher_first_published_at"] = e["first_published_at"]
      end
    end
  end

  def populate_published_at(to_update)
    editions_data.each_with_index do |e, i|
      next if e["published_at"].present? || e["publisher_published_at"].present? || e["state"] == "draft"

      next_edition_created_at = editions_data[i + 1]&.[]("created_at")

      to_update[e["id"]]["published_at"] = PublishedAtResolver.new(
        document, e, can_use_events?, next_edition_created_at
      ).call
    end
  end

  def populate_major_published_at(to_update)
    editions_data.each do |e|
      row = to_update[e["id"]]

      previous_major = editions_data
        .select { |p| p["update_type"] == "major" && p["user_facing_version"] < e["user_facing_version"] }
        .last

      major_published_at = MajorPublishedAtResolver.new(
        e, previous_major, to_update
      ).call

      if e["major_published_at"] != major_published_at
        row["major_published_at"] = major_published_at
      end

      if !within_1_sec(e["public_updated_at"], major_published_at) &&
          e["publisher_major_published_at"] != e["public_updated_at"]
        row["publisher_major_published_at"] = e["public_updated_at"]
      end
    end
  end

  def populate_last_edited_at(to_update)
    editions_data.each_with_index do |e, i|
      next if e["temporary_last_edited_at"].present? || e["publisher_last_edited_at"].present?
      row = to_update[e["id"]]

      next_edition_created_at = editions_data[i + 1]&.[]("created_at")
      row["temporary_last_edited_at"] = LastEditedAtResolver.new(
        document, e, next_edition_created_at, can_use_events?
      ).call

      if !within_1_sec(e["last_edited_at"], row["temporary_last_edited_at"])
        row["publisher_last_edited_at"] = e["last_edited_at"]
      end
    end
  end

  def can_use_events?
    return @can_use_events unless @can_use_events.nil?
    @can_use_events = Document.where(content_id: document.content_id).count == 1
  end

  def within_1_sec(date_a, date_b)
    diff = (date_b.to_f * 1000).to_i - (date_a.to_f * 1000).to_i
    diff.abs < 1000
  end

  def first_published_at
    @first_published_at_resolver ||= FirstPublishedAtResolver.new(
      document, editions_data, can_use_events?
    )
    @first_published_at_resolver.first_published_at
  end

  class FirstPublishedAtResolver
    def initialize(document, editions_data, can_use_events)
      @document = document
      @editions_data = editions_data
      @can_use_events = can_use_events
    end

    def first_published_at
      return @first_published_at if defined?(@first_published_at)
      @first_published_at = resolve
    end

  private

    attr_reader :document, :editions_data, :can_use_events

    def resolve
      resolve_from_action ||
        resolve_from_events ||
        resolve_from_first_edition
    end

    def resolve_from_previous_edition
      first = editions_data.find { |e| e["temporary_first_published_at"] }
      first&.[]("temporary_first_published_at")
    end

    def resolve_from_action
      Action
        .where(edition_id: editions_data.first["id"], action: "Publish")
        .pluck(:created_at)
        .first
    end

    def resolve_from_events
      return unless can_use_events
      Event.where(
        content_id: document.content_id,
        action: "Publish"
      ).order(id: :asc).limit(1).pluck(:created_at).first
    end

    def resolve_from_first_edition
      first_published_at = editions_data.first["first_published_at"]
      return unless first_published_at
      # If nano seconds on time aren't 0 we assume we set this date
      first_published_at.nsec != 0 ? first_published_at : nil
    end
  end

  class PublishedAtResolver
    def initialize(
      document, edition_data, can_use_events, next_edition_created_at
    )
      @document = document
      @edition_data = edition_data
      @can_use_events = can_use_events
      @next_edition_created_at = next_edition_created_at
    end

    def call
      resolve_from_action || resolve_from_events
    end

  private

    attr_reader :document, :edition_data, :can_use_events, :next_edition_created_at

    def resolve_from_action
      Action
        .where(edition_id: edition_data["id"], action: "Publish")
        .pluck(:created_at)
        .first
    end

    def resolve_from_events
      return unless can_use_events
      scope = Event.where(
        content_id: document.content_id,
        action: %w(Publish Unpublish),
      ).where("created_at > ?", edition_data["created_at"])

      if next_edition_created_at
        scope = scope.where("created_at < ?", next_edition_created_at)
      end

      scope.order(created_at: :asc).pluck(:created_at).first
    end
  end

  class MajorPublishedAtResolver
    def initialize(edition_data, previous_major_edition_data, to_update)
      @edition_data = edition_data
      @previous_major_edition_data = previous_major_edition_data
      @to_update = to_update
    end

    def call
      published_at || resolve_from_edition
    end

  private

    attr_reader :edition_data, :previous_major_edition_data, :to_update

    def published_at
      # We're making an assumption here that an update_type of major means it
      # was actually published as that, this seems pretty safe since it'd be
      # very unlikely and confusing were update_type on model and the one used
      # in publish differed
      if edition_data["update_type"] == "major"
        id = edition_data["id"]
        to_update[id]&.[]("published_at") || edition_data["published_at"]
      else
        id = previous_major_edition_data&.[]("id")
        to_update[id]&.[]("published_at") || previous_major_edition_data&.[]("published_at")
      end
    end

    def resolve_from_edition
      public_updated_at = edition_data["public_updated_at"]
      return unless public_updated_at
      # If nano seconds on time aren't 0 we assume we set this date
      public_updated_at.nsec != 0 ? public_updated_at : nil
    end
  end

  class LastEditedAtResolver
    def initialize(document, edition_data, next_edition_created_at, can_use_events)
      @document = document
      @edition_data = edition_data
      @next_edition_created_at = next_edition_created_at
      @can_use_events = can_use_events
    end

    def call
      resolve_from_action || resolve_from_events || resolve_from_edition
    end

  private

    attr_reader :document, :edition_data, :next_edition_created_at, :can_use_events

    def resolve_from_action
      Action.where(edition_id: edition_data["id"], action: "PutContent")
        .pluck(:created_at)
        .last
    end

    def resolve_from_events
      return unless can_use_events
      scope = Event.where(
        content_id: document.content_id,
        action: %w(PutContent PutContentWithLinks PutDraftContentWithLinks),
      ).where("created_at > ?", edition_data["created_at"])

      if next_edition_created_at
        scope = scope.where("created_at < ?", next_edition_created_at)
      end

      scope.order(created_at: :asc).pluck(:created_at).first
    end

    def resolve_from_edition
      last_edited_at = edition_data["last_edited_at"]
      return unless last_edited_at
      # If nano seconds on time aren't 0 we assume we set this date
      last_edited_at.nsec != 0 ? last_edited_at : nil
    end
  end
end
