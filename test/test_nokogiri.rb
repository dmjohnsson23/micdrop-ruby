# frozen_string_literal: true

require_relative "test_helper"
require "micdrop/ext/nokogiri"

SAMPLE_HTML5_1 = "<!doctype html>
<html>
  <head></head>
  <body>
    <article id='beans' class='product-listing'>
      <h1>Dried Beans</h1>
      <p class='price'>$999.99</p>
    </article>
  </body>
</html>"

SAMPLE_HTML5_FRAGMENT_1 = "<p class='fire'>This is on fire!</p>"

describe "Micdrop::Ext::Nokogiri" do # rubocop:disable Metrics/BlockLength
  describe :parse_html5 do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      subctx = ctx.parse_html5
      _(subctx).must_be_instance_of Micdrop::SubRecordContext

      _(subctx.record).must_be_nil
    end
    it "parses html" do
      ctx = Micdrop::ItemContext.new(nil, SAMPLE_HTML5_1)
      subctx = ctx.parse_html5
      _(subctx).must_be_instance_of Micdrop::SubRecordContext
      _(subctx.record).must_be_instance_of Nokogiri::HTML5::Document
    end
  end

  describe :parse_html5_fragment do
    before do
    end

    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      subctx = ctx.parse_html5_fragment
      _(subctx).must_be_instance_of Micdrop::SubRecordContext

      _(subctx.record).must_be_nil
    end
    it "parses html" do
      ctx = Micdrop::ItemContext.new(nil, SAMPLE_HTML5_FRAGMENT_1)
      subctx = ctx.parse_html5_fragment
      _(subctx).must_be_instance_of Micdrop::SubRecordContext
      _(subctx.record).must_be_instance_of Nokogiri::HTML5::DocumentFragment
    end
  end

  describe :decode_html5 do
    it "decodes html5" do
      ctx = Micdrop::ItemContext.new(nil, "&lt;&apos;&quot;")
      _(ctx.decode_html5).must_be_same_as ctx

      _(ctx.value).must_equal "<'\""
    end
  end

  describe :encode_html5 do
    it "encodes html5" do
      ctx = Micdrop::ItemContext.new(nil, "<'\"")
      _(ctx.encode_html5).must_be_same_as ctx

      _(ctx.value).must_equal "&lt;'\""
    end

    it "converts newlines to <br>" do
      ctx = Micdrop::ItemContext.new(nil, "Here are some\nlines")
      _(ctx.encode_html5(nl2br: true)).must_be_same_as ctx

      _(ctx.value).must_equal "Here are some<br/>lines"
    end
  end

  describe :take_content do
    it "takes the node content" do
      item = Micdrop::ItemContext.new(nil, ::Nokogiri::HTML5.fragment(SAMPLE_HTML5_FRAGMENT_1))
      rec = Micdrop::SubRecordContext.new(item, nil)
      ctx = rec.take_content

      _(ctx).must_be_instance_of Micdrop::ItemContext
      _(ctx.value).must_equal "This is on fire!"
    end
  end

  describe :at_css do
    it "searches the document" do
      item = Micdrop::ItemContext.new(nil, ::Nokogiri::HTML5.parse(SAMPLE_HTML5_1))
      ctx = Micdrop::SubRecordContext.new(item, nil)

      sub = ctx.at_css(".price")
      _(sub).must_be_instance_of Micdrop::SubRecordContext
      _(sub.record).must_be_instance_of Nokogiri::XML::Element
      _(sub.record.content).must_equal "$999.99"
    end
  end
end
