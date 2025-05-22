class ConvertHtmlToAst
  def self.call(html)
    html_node_to_ast_node(Nokogiri.parse(html).children.first)
  end

private

  def self.html_node_to_ast_node(node)
    result = {type: node.name}
    attributes = {}

    case node.name
    when "text"
      result[:content] = node.content
    else
      node.attributes.each do |_, attr|
        attributes[attr.name] = attr.value
      end
      result[:attributes] = attributes unless attributes.empty?

      result[:children] = node.children.map(&method(:html_node_to_ast_node))
    end

    result
  end
end
