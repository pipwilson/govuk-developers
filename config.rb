set :markdown_engine, :redcarpet

set :markdown,
  fenced_code_blocks: true,
  smartypants: true,
  with_toc_data: true

configure :development do
  activate :livereload
end

activate :sprockets

configure :build do
end

ignore 'schema.html.md.erb'

require_relative './lib/dashboard/dashboard'

helpers do
  def dashboard
    Dashboard.new
  end
end

require_relative './lib/content_schemas/content_schema'

ContentSchema.schema_names.each do |schema_name|
  schema = ContentSchema.new(schema_name)

  proxy "/content-schemas/#{schema_name}.html", "schema.html", locals: {
    schema: schema,
    page_title: "Schema: #{schema.schema_name}",
  }
end
