# frozen_string_literal: true

require "nokogiri"

module Micdrop
  ##
  # Extend ItemContext with HTML/XML functions
  class ItemContext
    ##
    # Alias for scope.enter.take_content
    def take_content(put: nil, convert: nil, apply: nil, &block)
      scope.enter.take_content(put: put, convert: convert, apply: apply, &block)
    end

    ##
    # Parse HTML and enter a sub-record context for the root node
    def parse_html(&block)
      doc = @value.nil? ? nil : ::Nokogiri::HTML.parse(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Parse HTML5 and enter a sub-record context for the root node
    def parse_html5(&block)
      doc = @value.nil? ? nil : ::Nokogiri::HTML5.parse(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Parse XML and enter a sub-record context for the root node
    def parse_xml(&block)
      doc = @value.nil? ? nil : ::Nokogiri::XML.parse(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Parse an HTML fragment and enter a sub-record context for the root node
    def parse_html_fragment(&block)
      doc = @value.nil? ? nil : ::Nokogiri::HTML.fragment(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Parse an HTML5 fragment and enter a sub-record context for the root node
    def parse_html5_fragment(&block)
      doc = @value.nil? ? nil : ::Nokogiri::HTML5.fragment(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Parse an XML fragment and enter a sub-record context for the root node
    def parse_xml_fragment(&block)
      doc = @value.nil? ? nil : Nokogiri::XML.fragment(@value)
      nokogiri_node_subrecord_helper(doc, block)
    end

    ##
    # Decode an HTML entity-encoded string to plain text
    def decode_html
      return self if @value.nil?

      frag = ::Nokogiri::HTML.fragment @value
      @value = frag.content
      self
    end

    ##
    # Encode a string using HTML entities
    def encode_html(nl2br: false)
      return self if @value.nil?

      frag = ::Nokogiri::HTML.fragment ""
      frag.content = @value
      @value = frag.to_s
      @value = @value.sub "\n", "<br/>" if nl2br
      self
    end

    ##
    # Decode an HTML5 entity-encoded string to plain text
    def decode_html5
      return self if @value.nil?

      frag = ::Nokogiri::HTML5.fragment @value
      @value = frag.content
      self
    end

    ##
    # Encode a string using HTML5 entities
    def encode_html5(nl2br: false)
      return self if @value.nil?

      frag = ::Nokogiri::HTML5.fragment ""
      frag.content = @value
      @value = frag.to_s
      @value = @value.sub "\n", "<br/>" if nl2br
      self
    end

    ##
    # Decode an XML entity-encoded string to plain text
    def decode_xml
      return self if @value.nil?

      frag = ::Nokogiri::XML.fragment @value
      @value = frag.content
      self
    end

    ##
    # Encode a string using XML entities
    def encode_xml
      return self if @value.nil?

      frag = ::Nokogiri::XML.fragment ""
      frag.content = @value
      @value = frag.to_s
      self
    end

    private

    def nokogiri_node_subrecord_helper(node, block)
      item_ctx = ItemContext.new @record_context, node
      subrec_ctx = SubRecordContext.new item_ctx, @record_context
      subrec_ctx.instance_eval(&block)
      subrec_ctx
    end
  end

  ##
  # Extend RecordContext with HTML/XML functions
  class RecordContext
    ##
    # Take the text content of the XML or HTML node
    def take_content(put: nil, convert: nil, apply: nil, &block)
      value = @record&.content
      process_item_helper(value, put, convert, apply, block)
    end

    def xpath(*args, &block)
      nokogiri_node_subrecord_helper(@record.xpath(*args), block)
    end

    def at_xpath(*args, &block)
      nokogiri_node_subrecord_helper(@record.at_xpath(*args), block)
    end

    def css(*args, &block)
      nokogiri_node_subrecord_helper(@record.css(*args), block)
    end

    def at_css(*args, &block)
      nokogiri_node_subrecord_helper(@record.at_css(*args), block)
    end

    private

    def nokogiri_node_subrecord_helper(node, block)
      item_ctx = ItemContext.new self, node
      subrec_ctx = SubRecordContext.new item_ctx, self
      subrec_ctx.instance_eval(&block)
      subrec_ctx
    end
  end
end
