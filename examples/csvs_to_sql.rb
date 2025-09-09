# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "micdrop"
require "sequel"
require "csv"
require "date"
require "micdrop/ext/sequel"

DB = Sequel.sqlite "test.db"

# Create the destination data structure.
# Obviously in a real import script, these would probably already exist.

DB.create_table :users do
  primary_key :id
  String :username, size: 255
  TrueType :active
  String :pass_hash
  String :email
  String :f_name
  String :l_name
  String :sex, size: 1, fixed: true
  Date :dob
  String :occupation
  Date :registration_date
  Fixnum :_tmp_id # Add a temporary column for storing the old system IDs
end

DB.create_table :user_phones do
  primary_key :id
  foreign_key :user_id, :users, null: false
  String :type
  String :display
  String :search
end

DB.create_table :clients do
  primary_key :id
  String :name
  String :website
  Date :registration_date
  Fixnum :_tmp_id # Add a temporary column for storing the old system IDs
end

DB.create_table :client_addresses do
  primary_key :id
  foreign_key :client_id, :clients, null: false
  String :line1
  String :line2
  String :city
  String :county
  String :state
  String :zip
  String :country
end

DB.create_table :client_contacts do
  primary_key :id
  foreign_key :client_id, :clients, null: false
  String :f_name
  String :l_name
  String :title
  String :email
  Fixnum :_tmp_id # Add a temporary column for storing the old system IDs
end

DB.create_table :client_contact_phones do
  primary_key :id
  foreign_key :client_contact_id, :client_contacts, null: false
  String :type
  String :display
  String :search
end

# Now start the migration

# For the first pass, we'll import legacy users into the new system
source = CSV.read "data/people-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:users]

Micdrop.migrate source, sink do
  # Define mappings for common fields
  take "Index", put: :_tmp_id
  take "First Name", put: :f_name
  take "Last Name", put: :l_name
  take "Email", put: :email
  take "Job Title", put: :occupation
  # Use sprintf-style template strings in the pipeline
  take "User Id" do
    format_string "_legacy_user_%s"
    put :username
  end
  # Use hash lookups as lookup tables to convert values
  take "Sex" do
    lookup({ "Male" => "m", "Female" => "f" })
    put "sex"
  end
  # Pipeline methods for common tasks such as parsing and formatting dates also exist
  take "Date of birth" do
    parse_date
    put :dob
  end
  # You can also put static or dynamically computed values in the sink for required items not found in the source data.
  put :registration_date, Date.today
  put :active, false
end

# Create a reusable lookup table for mapping the original source user IDs to the new destination user IDs user IDs
# during subsequent migrations. (If this is expected to be too large for your memory constraints, you can also query the
# new database directly during subsequent migrations, but for smaller datasets using an in-memory hash will usually be
# more performant.)
user_lookup = DB[:users].select_hash(:_tmp_id, :id)

# The new system uses a separate table for storing phone number data, so we make a second pass
# over the same source to extract that
source = CSV.read "data/people-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:user_phones]

Micdrop.migrate source, sink do
  put :type, "Other"
  # We can use our lookup table to map the user IDs correctly
  take "Index" do
    parse_int
    lookup user_lookup
    put :user_id
  end
  # We can use `skip if` to skip rows that don't have a value in this column
  take "Phone" do
    skip if value == ""
    put :display
  end
  # Functions or other callables can be used in pipelines for complex transformations.
  # Note that the `string_replace` method would be a better way of doing the following; this example is merely to
  # demonstrate what can be done if an existing method does not already provide the needed functionality.
  take "Phone" do
    convert { |value| value.gsub(/[^0-9]/, "") }
    put :search
  end
end

# We can import from another file in much the same way
source = CSV.read "data/customers-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:clients]

Micdrop.migrate source, sink do
  take "Index", put: :_tmp_id
  take "Company", put: :name
  take "Subscription Date" do
    parse_date
    put :registration_date
  end
  take "Website", put: :website
end

client_lookup = DB[:clients].select_hash(:_tmp_id, :id)

# A second pass with that file
source = CSV.read "data/customers-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:client_contacts]

Micdrop.migrate source, sink do
  take "Index", put: :_tmp_id
  take "Index" do
    parse_int
    lookup client_lookup
    put :client_id
  end
  take "First Name", put: :f_name
  take "Last Name", put: :l_name
  take "Email", put: :email
end

client_contact_lookup = DB[:client_contacts].select_hash(:_tmp_id, :id)

# And a third for the addresses--we can take as many passes as we need to normalize our data
source = CSV.read "data/customers-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:client_addresses]

Micdrop.migrate source, sink do
  take "Index" do
    parse_int
    lookup client_lookup
    put :client_id
  end
  take "City", put: :city
  take "Country", put: :country
end

# Sometimes, one record in the source data may need to turn into multiple records in the destination. You can achieve
# this by flushing to the sink, which will create a desination record and reset, but maintain the same source record.
source = CSV.read "data/customers-100.csv", headers: true
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:client_contact_phones]

Micdrop.migrate source, sink do
  take "Index" do
    parse_int
    lookup client_contact_lookup
    put :client_contact_id
  end
  put :type, "Other"
  # There is a "Phone 1" and "Phone 2" in the source, but the destination requires separare records for each. We'll do
  # Phone 1 first.
  take "Phone 1" do
    skip if value == ""
    put :display
    # We don't have to end a block wtih put; we can put multiple values from the same put if needed
    string_replace(/[^0-9]/, "")
    put :search
  end
  # Now we can insert the first of the two phone number records. Normally the collector would be reset when flushing,
  # but here for convenience we'll prevent that. After all, only one value is different in the second record, so it
  # makes more sense to just overwrite that value rather than start with a blank slate.
  flush reset: false
  take "Phone 2" do
    skip if value == ""
    put :display
    string_replace(/[^0-9]/, "")
    put :search
  end
end
