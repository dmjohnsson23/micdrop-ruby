# frozen_string_literal: true

require_relative "test_helper"
require "sequel"
require "micdrop/ext/sequel"

class TestSequel < Minitest::Test
  def setup # rubocop:disable Metrics/MethodLength
    @db = Sequel.sqlite

    @db.create_table :people do
      primary_key :id
      String :first_name
      String :last_name
      String :title
      String :status
    end

    people = @db[:people]
    people.insert(id: 1, title: "Farm Boy", first_name: "Wesley", last_name: "", status: "alive")
    people.insert(id: 2, title: "", first_name: "Inigo", last_name: "Montoya", status: "alive")
    people.insert(id: 3, title: "", first_name: "Buttercup", last_name: "", status: "alive")
  end

  def test_as_source # rubocop:disable Metrics/MethodLength
    source = @db[:people]
    sink = []

    Micdrop.migrate source, sink do
      take :first_name, put: :first_name
      take :last_name, put: :last_name
      take :title, put: :title
      take :status, put: :status
    end

    assert_equal [
      { title: "Farm Boy", first_name: "Wesley", last_name: "", status: "alive" },
      { title: "", first_name: "Inigo", last_name: "Montoya", status: "alive" },
      { title: "", first_name: "Buttercup", last_name: "", status: "alive" }
    ], sink
  end

  def test_as_source_paged # rubocop:disable Metrics/MethodLength
    source = @db[:people].order(:id).paged_each
    sink = []

    Micdrop.migrate source, sink do
      take :first_name, put: :first_name
      take :last_name, put: :last_name
      take :title, put: :title
      take :status, put: :status
    end

    assert_equal [
      { title: "Farm Boy", first_name: "Wesley", last_name: "", status: "alive" },
      { title: "", first_name: "Inigo", last_name: "Montoya", status: "alive" },
      { title: "", first_name: "Buttercup", last_name: "", status: "alive" }
    ], sink
  end

  def test_insert_sink # rubocop:disable Metrics/MethodLength
    source = [
      { id: 4, title: "Prince", first_name: "", last_name: "Humperdink", status: "alive" }
    ]
    sink = Micdrop::Ext::Sequel::InsertSink.new(@db[:people])

    Micdrop.migrate source, sink do
      take :id, put: :id
      take :first_name, put: :first_name
      take :last_name, put: :last_name
      take :title, put: :title
      take :status, put: :status
    end

    prince = @db[:people].where(id: 4).all

    assert_equal [
      { id: 4, title: "Prince", first_name: "", last_name: "Humperdink", status: "alive" }
    ], prince
  end

  def test_update_sink # rubocop:disable Metrics/MethodLength
    source = [
      { id: 1, title: "Dread Pirate", first_name: "", last_name: "Roberts", status: "mostly dead" },
      { id: 2, title: "", first_name: "Inigo", last_name: "Montoya", status: "wounded?" },
      { id: 3, title: "Princess", first_name: "Buttercup", last_name: "", status: "alive" }
    ]
    sink = Micdrop::Ext::Sequel::UpdateSink.new(@db[:people], :id)

    Micdrop.migrate source, sink do
      take :id, put: :id
      take :first_name, put: :first_name
      take :last_name, put: :last_name
      take :title, put: :title
      take :status, put: :status
    end

    people = @db[:people].all

    assert_equal source, people
  end

  def test_insert_update_sink # rubocop:disable Metrics/MethodLength
    source = [
      { id: 1, title: "Dread Pirate", first_name: "", last_name: "Roberts", status: "mostly dead" },
      { id: 2, title: "", first_name: "Inigo", last_name: "Montoya", status: "wounded?" },
      { id: 3, title: "Princess", first_name: "Buttercup", last_name: "", status: "alive" },
      { id: 4, title: "Prince", first_name: "", last_name: "Humperdink", status: "alive" }
    ]
    sink = Micdrop::Ext::Sequel::InsertUpdateSink.new(@db[:people], :id)

    Micdrop.migrate source, sink do
      take :id, put: :id
      take :first_name, put: :first_name
      take :last_name, put: :last_name
      take :title, put: :title
      take :status, put: :status
    end

    people = @db[:people].all

    assert_equal source, people
  end

  # TODO: test we can use the db to do lookups
end
