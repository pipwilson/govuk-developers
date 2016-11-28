require 'json'
require 'active_support/core_ext/string'
require 'govuk_schemas'

class ContentSchema
  def self.schema_names
    Dir.glob("#{GovukSchemas::CONTENT_SCHEMA_DIR}/dist/formats/*").map { |directory| File.basename(directory) } - %w[gone special_route]
  end

  attr_reader :schema_name

  def initialize(schema_name)
    @schema_name = schema_name
  end

  def table_of_properties(properties)
    return unless properties

    rows = properties.map do |name, attrs|
      "<tr><td><strong>#{name}</strong> #{possible_types(attrs)}</td> <td>#{display_attribute_value(attrs)}</td></tr>"
    end

    "<table class='schema-table'>#{rows.join("\n")}</table>"
  end

  def display_attribute_value(attrs)
    return unless attrs
    if attrs['properties']
      table_of_properties(attrs['properties'])
    else
      [enums(attrs), attrs['description']].join
    end
  end

  def enums(attrs)
    return unless attrs['enum']
    "Allowed values: " + attrs['enum'].map { |value| "<code>#{value}</code>" }.join(" or ")
  end

  def publisher_properties
    schema = publisher_schema
    inline_definitions(schema['properties'], schema['definitions'])
  end

  def random_publisher_payload
    GovukSchemas::RandomExample.new(schema: publisher_schema).payload
  end

  def random_frontend_payload
    GovukSchemas::RandomExample.new(schema: frontend_schema).payload
  end

  def random_links_payload
    GovukSchemas::RandomExample.new(schema: links_schema).payload
  end

  def publisher_schema
    GovukSchemas::Schema.find(publisher_schema: schema_name)
  end

  def links_schema
    GovukSchemas::Schema.find(links_schema: schema_name)
  end

  def frontend_schema
    GovukSchemas::Schema.find(frontend_schema: schema_name)
  end

  def links_properties
    find_with_inlined_definitions(links_schema: schema_name)
  end

  def frontend_properties
    find_with_inlined_definitions(frontend_schema: schema_name)
  end

  def possible_types(attrs)
    return unless attrs
    possible_types = attrs['type'] ? [attrs] : attrs['anyOf']
    return unless possible_types
    possible_types.map { |a| "<code>#{a['type']}</code>" }.join(" or ")
  end

private

  def find_with_inlined_definitions(what)
    schema = GovukSchemas::Schema.find(what)
    inline_definitions(schema['properties'], schema['definitions'])
  rescue Errno::ENOENT
  end

  # Inline any keys that use definitions
  def inline_definitions(original_properties, definitions)
    original_properties.each do |k, v|
      next unless v['$ref']
      original_properties[k] = definitions[v['$ref'].gsub('#/definitions/', '')]
    end

    # Inline any keys that use definitions
    if original_properties['details']
      original_properties['details']['properties'].each do |k, v|
        next unless v['$ref']
        definition_name = v['$ref'].gsub('#/definitions/', '')
        original_properties['details']['properties'][k] = definitions.fetch(definition_name)
      end
    end

    # Sort by keyname
    Hash[original_properties.sort_by(&:first)]
  end
end
