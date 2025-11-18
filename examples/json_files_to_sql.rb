# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "micdrop"
require "sequel"
require "micdrop/ext/sequel"

DB = Sequel.sqlite "test.db"

# Create the destination data structure.
# Obviously in a real import script, these would probably already exist.

DB.create_table :people do
  primary_key :id
  String :f_name
  String :l_name
  String :addr1
  String :addr2
  String :city
  String :state
  String :zip
  String :_tmp_id # Add a temporary column for storing the old system IDs
end

# Now start the migration

# Our source will iterate over all the JSON files in the given directory
source = Micdrop::FilesSource.new(__dir__, glob: "data/json/*.json")
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:people]

Micdrop.migrate source, sink do
  # The files source exposes the basename and content as takeable items
  take :basename, put: :_tmp_id
  take(:content).parse_json do
    # parse_json accepts a block that will enter the sub-record
    take "residency" do
      regex(/(?<street>.+?) ?(?<unit>(?:Apt\.?|Suite|Unit|#) [#0-9a-zA-Z-]+)?\n(?<city>.+?), (?<state>[A-Z]{2}) (?<zip>\d{5}(?:-\d{4})?)/) do
        # regex also enters a sub-record
        take :street, put: :addr1
        take :unit, put: :addr2
        take :city, put: :city
        take :state, put: :state
        take :zip, put: :zip
      end
    end
    take "name" do
      split " " do
        # split can enter a sub-record as well
        take 0, put: :f_name
        take 1, put: :l_name
      end
    end
  end
end
