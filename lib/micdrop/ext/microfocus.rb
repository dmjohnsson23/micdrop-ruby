require "date"
require "forwardable"

module Micdrop
  module Ext
    ##
    # A simple parser to extract data from a "Micro Focus File with Header (DAT)" file.
    #
    # Based on this spec: https://www.microfocus.com/documentation/server-express/sx20books/fhfile.htm
    #
    # This format comes from old COBOL programs, and each file is conceptually similar to an SQL
    # database table. Unlike SQL though, these DAT files lack type information; each row is raw
    # binary and must be unpacked.
    #
    # This does not implement the full spec, and is not well tested, but "works on my machine".
    module Microfocus
      ##
      # A header value that appears at the beginning of each record to determine the record type
      module RecordType
        DUPLICATE_SYSTEM    = 0b0001
        DELETED             = 0b0010
        SYSTEM              = 0b0011
        NORMAL              = 0b0100
        REDUCED             = 0b0101
        POINTER             = 0b0110
        POINTER_REF         = 0b0111
        REDUCED_POINTER_REF = 0b1000
      end

      ##
      # Flag indicating how records are organized in the file
      module RecordOrganization
        SEQUENTIAL = 1
        INDEXED = 2
        RELATIVE = 3
      end

      ##
      # Representation of a single record within a file
      class Record
        extend Forwardable

        def initialize(type, body, unpack_spec: nil, unpack_mapping: nil)
          @type = type
          @body = body
          @fields = nil
          unpack unpack_spec, unpack_mapping unless unpack_spec.nil?
        end

        attr_reader :type, :body, :fields

        def_delegators :@fields, :[], :each

        private

        def unpack(spec, mapping = nil)
          fields = @body.unpack spec
          fields = if mapping.nil?
                     fields
                   else
                     mapping.transform_values { |value| fields[value] }
                   end
          @fields = fields.freeze
        end
      end

      ##
      # Read a MicroFocus data file
      class MicroFocusReader
        def initialize(data_file, unpack_spec: nil, unpack_mapping: nil)
          @data_file = data_file
          @unpack_spec = unpack_spec
          @unpack_mapping = unpack_mapping
          read_data_header
        end

        attr_reader :creation_time, :compression, :index_type, :variable_length, :min_legth, :max_length, :index_version

        def long_records?
          @long_records
        end

        def sequential?
          @organization == RecordOrganization::SEQUENTIAL
        end

        def indexed?
          @organization == RecordOrganization::INDEXED
        end

        def relative?
          @organization == RecordOrganization::RELATIVE
        end

        def each
          return enum_for :each unless block_given?

          yield read_record until @data_file.eof?
        end

        private

        def read_data_header
          parse_data_file_header @data_file.read(128)
        end

        def read_record
          header = @data_file.read(@long_records ? 4 : 2)
          type = header.unpack1("C") >> 4
          length = header.unpack1(@long_records ? "N" : "n") & (@long_records ? 0xFFFFFFF : 0xFFF)
          body = @data_file.read length
          scan_padding
          Record.new type, body, unpack_spec: @unpack_spec, unpack_mapping: @unpack_mapping
        end

        ##
        # Parse the first four bytes of the header, which are used to determine the record size
        def parse_data_file_header(data)
          # The first 4 bits are the record type, which must be SYSTEM
          type = data.unpack1("C") >> 4
          raise StandardError, "This file does not have a valid header" unless type == RecordType::SYSTEM

          # The next 12 bits (or 28 bits, depending on the max record size) are the header record size
          length = data.unpack1("n") & 0xFFF
          if length == 126
            # Header data is 126 bytes, max record length is less than 4095 bytes
            @long_records = false
          elsif length == 0
            # Header data is 124 bytes, max record length is 4095 bytes or greater
            length = data.unpack1("N") & 0xFFF
            raise StandardError, "Invalid header record length" unless length == 124

            @long_records = true
          else
            raise StandardError, "Invalid header record length"
          end

          # Regardless of the listed header length, actual header data always at the same byte offsets
          (
              @db_seq,
              integrity, # The specs say this integrity flag is 3 bytes, not 2, but I think the spec must be wrong
              creation_time,
              special62,
              @organization,
              @compression,
              @index_type,
              variable_length,
              @min_legth,
              @max_length,
              @index_version
          ) = data.unpack "x4 n n A14 x14 n x C x C x C x C x5 N N x46 N"

          # Check integrity
          raise StandardError, "Integrity flag non-zero; file is corrupt" if integrity != 0
          raise StandardError, "Bytes 36-37 not equal to 64; file is corrupt" if special62 != 62

          # Type-cast some of the header values
          @creation_time = DateTime.strptime creation_time[0..11], "%y%m%d%H%M%S"
          @variable_length = !!variable_length.nil?
        end

        ##
        # Scan forward to the next non-null byte
        def scan_padding
          # TODO: This is a work-around because it seems I don't have align_cursor working correctly yet
          return if @data_file.eof?

          return if @data_file.eof? until @data_file.readbyte.positive?
          @data_file.seek(-1, :CUR)
        end

        ##
        # Aligns the file cursor to the next address which is a multiple of the data alignment value
        #
        # Automatically detect the the alignment from the index if not provided
        #
        # Index formats 1 and 2 have no alignment, 3 and 4 are aligned to 4 bytes, and 8 is aligned to 8 bytes
        def align_cursor
          alignment = if @index_type < 3
                        return # offset of 1, so we don't need to do anything
                      elsif @index_type < 5
                        4
                      else
                        8
                      end

          offset = @data_file.tell % alignment
          @file.seek offset, :CUR if offset
        end
      end

      ##
      # This is the main entrypoint to read a file, and its output is usable as a source.
      #
      # `unpack_spec` is an optional spec, as would be passed to `String#unpack`, to extract the
      # individual columns from the record. You may also provice an `unpack_mapping` which maps more
      # human-readable columns names to column indexes.
      def self.read_microfocus_file(filename, unpack_spec: nil, unpack_mapping: nil)
        File.open filename, "rb" do |file|
          reader = MicroFocusReader.new file, unpack_spec: unpack_spec, unpack_mapping: unpack_mapping
          reader.each.entries
        end
      end
    end
  end

  ##
  # Extend ItemContext with parse_microfocus
  class ItemContext
    ##
    # Parse a string as JSON
    #
    # If a block is provided, it will act as a record context where object properties can be taken.
    #
    # If include_header is true, the value will be a hash containing both the header information
    # and the actual records.
    def parse_microfocus(include_header: false, unpack_spec: nil, unpack_mapping: nil, &block)
      return self if @value.nil?

      reader = Micdrop::Ext::Microfocus::MicroFocusReader.new @value, unpack_spec: unpack_spec,
                                                                      unpack_mapping: unpack_mapping
      @value = if include_header
                 {
                   creation_time: reader.creation_time,
                   compression: reader.compression,
                   index_type: reader.index_type,
                   variable_length: reader.variable_length,
                   min_legth: reader.min_legth,
                   max_length: reader.max_length,
                   index_version: reader.index_version,
                   records: reader.each.entries
                 }
               else
                 reader.each.entries
               end
      enter(&block) unless block.nil?
      self
    end
  end
end
