class Reports::TableReporter

  def self.call
    new.call
  end

  def initialize
    super
  end

  def call
    tables = []
    tables_orgs = []
    content_ids = []
    Edition.joins(:document).where.not(content_store: nil).find_each do |e|
      tables <<  [e.id, e.content_id, "https://gov.uk#{e.base_path}", e.document_type, e.schema_name] if /<table/ =~ e.details.to_s
    end

    tables.each do |edition|
      content_ids << [edition, Link.left_outer_joins(:link_set)
                                 .where(link_type: "organisations")
                                 .where("links.edition_id = ? OR link_sets.content_id = ?", edition[0], edition[1])
                                 .pluck(:target_content_id)]
    end

    content_ids.each do |ci|
      org = Edition.joins(:document).where("documents.content_id": ci[1]).where(state: :published).pluck(:title)
      tables_orgs << ci[0] + [org]
    end

    pp table_orgs
  end

  private_class_method :new
end
