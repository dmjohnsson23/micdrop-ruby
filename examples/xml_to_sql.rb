# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "micdrop"
require "sequel"
require "micdrop/ext/sequel"
require "micdrop/ext/nokogiri"

DB = Sequel.sqlite "test.db"

# Create the destination data structure.
# Obviously in a real import script, these would probably already exist.

DB.create_table :products do
  String :code, primary_key: true
  String :name
  String :category
  BigDecimal :price, size: [6, 2]
  FixNum :stock
end

DB.create_table :product_specs do
  String :code
  String :key
  String :value
  primary_key %i[code key]
end

# Now start the migration
document = Nokogiri::XML.parse File.open File.join(__dir__, "data/catalog.xml")

# Our source will iterate over the <product> elements in the XML document
source = document.css("product")
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:products]

Micdrop.migrate source, sink do
  # The files source exposes the basename and content as takeable items
  take "id", put: :code
  at_css("name").take_content put: :name
  at_css("category").take_content put: :category
  at_css("price").take_content do
    parse_float
    put :price
  end
  at_css("quantity").take_content put: :stock
end

# Then over the individual specs
source = document.css("product")
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:product_specs]

Micdrop.migrate source, sink do
  # The files source exposes the basename and content as takeable items
  code = take "id"
  css("specifications > *").each_subrecord(flush: true, reset: true) do
    code.put :code
    take_node_name do
      lookup({
               "battery" => "Battery",
               "buttons" => "Button Count",
               "connectivity" => "Connectivity",
               "display" => "Screen",
               "dpi" => "Screen DPI",
               "graphics" => "GPU",
               "processor" => "CPU",
               "ram" => "Memory",
               "storage" => "Storage"
             })
      put :key
    end
    take_content.put :value
  end
end
