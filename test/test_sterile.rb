require "test_helper"

class TestSterile < Minitest::Test
  def test_decode_entities
    # basic tests
    assert_equal "", Sterile.decode_entities("")
    assert_equal "xyz", Sterile.decode_entities("xyz")
    assert_equal "“Hey” you", Sterile.decode_entities("&ldquo;Hey&rdquo; you")

    # base 10, base 16, named
    %w[&#176; &#000176; &#x000b0; &#x000B0; &deg;].each do |s|
      assert_equal "°", Sterile.decode_entities(s)
    end

    # don't accidentally double escape
    assert_equal "&amp;", Sterile.decode_entities("&#38;amp;")

    # string is not modified, so this should not assert
    Sterile.decode_entities("hi there".freeze)
  end

  def test_encode_entities
    assert_equal "&ldquo;Hey&rdquo; you", Sterile.encode_entities("“Hey” you")
  end

  def test_gsub_tags
    assert_equal "A<i>B</i>C", Sterile.gsub_tags("a<i>b</i>c", &:upcase)
  end

  def test_plain_format
    s = "&#169; &copy; &#8482; &trade;"
    assert_equal "(c) (c) (tm) (tm)", Sterile.plain_format(s)
  end

  def test_plain_format_tags
    s = '<i x="&copy;">&copy;</i>'
    assert_equal '<i x="&copy;">(c)</i>', Sterile.plain_format_tags(s)
  end

  def test_scan_tags
    text = []
    Sterile.scan_tags("a<i>b</i>c") { |i| text << i }
    assert_equal %w[a b c], text
  end

  def test_sluggerize
    assert_equal "hello-world", Sterile.sluggerize("Hello world!")
  end

  def test_smart_format
    s = "\"He said, 'Away, Drake!'\""
    assert_equal "“He said, ‘Away, Drake!’”", Sterile.smart_format(s)
  end

  def test_smart_format_tags
    # ?
  end

  def test_sterilize
    assert_equal "nasty", Sterile.sterilize("<b>nåsty</b>")
  end

  def test_strip_tags
    s = 'Visit <a href="http://example.com">site!</a>'
    assert_equal "Visit site!", Sterile.strip_tags(s)
  end

  def test_titlecase
    s = "Q&A: 'That's what happens'"
    assert_equal "Q&A: 'That's What Happens'", Sterile.titlecase(s)
  end

  def test_transliterate
    assert_equal "yucky", Sterile.transliterate("ýůçký")
  end

  def test_trim_whitespace
    assert_equal "Hello world!", Sterile.trim_whitespace(" Hello  world! ")
  end
end
