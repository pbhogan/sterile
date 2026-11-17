require "test_helper"

class TestSterile < Minitest::Test

  def test_decode_entities
    assert_equal "“Hey” you", Sterile.decode_entities("&ldquo;Hey&rdquo; you")

    # try all variants
    assert_equal "°", Sterile.decode_entities("&deg;")
    assert_equal "°", Sterile.decode_entities("&#176;")
    assert_equal "°", Sterile.decode_entities("&#000176;")
    assert_equal "°", Sterile.decode_entities("&#x000b0;")
    assert_equal "°", Sterile.decode_entities("&#x000B0;")
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

  def test_smart_format_times
    assert_equal "1×1", Sterile.smart_format("1x1")
    assert_equal "0×1", Sterile.smart_format("0x1")
    assert_equal "1×0", Sterile.smart_format("1x0")
    assert_equal "12×21", Sterile.smart_format("12x21")
    assert_equal "01x1", Sterile.smart_format("01x1")
    assert_equal "1x01", Sterile.smart_format("1x01")
  end

  def test_smart_format_quote_after_dash
    assert_equal "then—“go” and then—‘go’", Sterile.smart_format(%q{then—"go" and then—'go'})
    assert_equal "word—“go” and word—‘go’", Sterile.smart_format(%q{word--"go" and word--'go'})
    assert_equal "1914–“go”", Sterile.smart_format(%q{1914–"go"})
    assert_equal "composition—“… Because", Sterile.smart_format(%q{composition--"... Because})
    assert_equal "composition—“. . . Because", Sterile.smart_format(%q{composition--". . . Because})
    assert_equal "rock—’90s style", Sterile.smart_format(%q{rock--'90s style})
  end

  def test_smart_format_closing_quote_after_dash
    assert_equal "“Hello—” he said", Sterile.smart_format(%q{"Hello--" he said})
    assert_equal "“Wait—”, he said. “No—”.", Sterile.smart_format(%q{"Wait--", he said. "No--".})
    assert_equal "“I can’t—”", Sterile.smart_format(%q{"I can't--"})
    assert_equal "‘Why—’ he said", Sterile.smart_format(%q{'Why--' he said})
    assert_equal "“Soda—” and “Movie—”—or", Sterile.smart_format(%q{"Soda--" and "Movie--"--or})
  end

  def test_smart_format_capitalized_elisions
    assert_equal "’Tis so. ’Twas so. ’Twill be. ’Twere so. ’Tain’t so.", Sterile.smart_format("'Tis so. 'Twas so. 'Twill be. 'Twere so. 'Tain't so.")
    assert_equal "“’Tis the season,” ’tis said", Sterile.smart_format(%q{"'Tis the season," 'tis said})
    assert_equal "‘Tissue’ and ‘Twist’", Sterile.smart_format("'Tissue' and 'Twist'")
  end

  def test_smart_format_quotes_after_non_breaking_space
    assert_equal "word “quote” and ‘quote’", Sterile.smart_format("word \"quote\" and 'quote'")
    assert_equal "word&nbsp;“quote” and&nbsp;‘quote’", Sterile.smart_format(%q{word&nbsp;"quote" and&nbsp;'quote'})
    assert_equal "“quote” word and ‘quote’ word", Sterile.smart_format("\"quote\" word and 'quote' word")
    assert_equal "“quote”&nbsp;word and ‘quote’&nbsp;word", Sterile.smart_format(%q{"quote"&nbsp;word and 'quote'&nbsp;word})
    assert_equal "said ” and", Sterile.smart_format("said \" and")
  end

  def test_smart_format_tags_quotes_after_non_breaking_space
    assert_equal "word&nbsp;&ldquo;quote&rdquo;&nbsp;and&nbsp;&lsquo;quote&rsquo;", Sterile.smart_format_tags(%q{word&nbsp;"quote"&nbsp;and&nbsp;'quote'})
    assert_equal "<em>word&nbsp;</em>&ldquo;quote&rdquo;", Sterile.smart_format_tags(%q{<em>word&nbsp;</em>"quote"})
  end

  def test_smart_format_afrikaans_article
    assert_equal "Dit was ’n besef—’n waarheid. ’n Man", Sterile.smart_format("Dit was 'n besef--'n waarheid. 'n Man")
    assert_equal "the letter ‘n’ and ‘no’", Sterile.smart_format("the letter 'n' and 'no'")
  end

  def test_smart_format_leaves_three_hyphens
    assert_equal "Go to h---, he said", Sterile.smart_format("Go to h---, he said")
    assert_equal "one—two", Sterile.smart_format("one--two")
    assert_equal "——", Sterile.smart_format("----")
    assert_equal "——-", Sterile.smart_format("-----")
    assert_equal "———", Sterile.smart_format("------")
  end

  def test_smart_format_tags_quotes_around_tags
    assert_equal "&ldquo;<em>Word</em>&rdquo; and &lsquo;<em>Word</em>&rsquo;", Sterile.smart_format_tags(%q{"<em>Word</em>" and '<em>Word</em>'})
    assert_equal "<em>&ldquo;Word&rdquo;</em> and <em>&lsquo;Word&rsquo;</em>", Sterile.smart_format_tags(%q{<em>"Word"</em> and <em>'Word'</em>})
    assert_equal "He said, &ldquo;<em>Go</em>.&rdquo; Then &ldquo;<em>stop</em>,&rdquo; he said.", Sterile.smart_format_tags(%q{He said, "<em>Go</em>." Then "<em>stop</em>," he said.})
    assert_equal "&ldquo;<em>A</em>&rdquo; &ldquo;<b><em>B</em></b>&rdquo; (&ldquo;<em>C</em>&rdquo;)", Sterile.smart_format_tags(%q{"<em>A</em>" "<b><em>B</em></b>" ("<em>C</em>")})
    assert_equal "<em>Dan.</em> &lsquo;And then&rsquo;", Sterile.smart_format_tags(%q{<em>Dan. </em>'And then'})
  end

  def test_smart_format_tags_apostrophe_across_tags
    assert_equal "<em>Bible</em>&rsquo;s and <em>Bibles</em>&rsquo; covers", Sterile.smart_format_tags(%q{<em>Bible</em>'s and <em>Bibles</em>' covers})
    assert_equal "Armstrong<span>&rsquo;s footsteps</span>", Sterile.smart_format_tags(%q{Armstrong<span>'s footsteps</span>})
    assert_equal "<span>GM</span><em>&rsquo;s</em> top", Sterile.smart_format_tags(%q{<span>GM</span><em>'s</em> top})
    assert_equal "don<em>&rsquo;t</em>", Sterile.smart_format_tags(%q{don<em>'t</em>})
    assert_equal "described as &lsquo;<em>standing</em>&rsquo; there", Sterile.smart_format_tags(%q{described as '<em>standing</em>' there})
    assert_equal "<em>Youth &rsquo;81</em> magazine", Sterile.smart_format_tags(%q{<em>Youth '81</em> magazine})
  end

  def test_smart_format_tags_quote_after_dash_across_tags
    assert_equal "word&mdash;&ldquo;<em>Quote</em>&rdquo;&mdash;word", Sterile.smart_format_tags(%q{word--"<em>Quote</em>"--word})
    assert_equal "<em>Doe v. Bolton&mdash;</em>&ldquo;viability&rdquo; was", Sterile.smart_format_tags(%q{<em>Doe v. Bolton--</em>"viability" was})
    assert_equal "<em>word</em>&mdash;&ldquo;quote&rdquo;", Sterile.smart_format_tags(%q{<em>word</em>—"quote"})
    assert_equal "&ldquo;<em>Wait&mdash;</em>&rdquo; he said", Sterile.smart_format_tags(%q{"<em>Wait--</em>" he said})
  end

  def test_smart_format_tags_starts_over_in_each_block
    assert_equal "<p>one</p><p>&lsquo;two&rsquo;</p>", Sterile.smart_format_tags(%q{<p>one</p><p>'two'</p>})
    assert_equal "<p>one</p>&ldquo;two&rdquo;", Sterile.smart_format_tags(%q{<p>one</p>"two"})
    assert_equal "<p>one<br>&ldquo;two&rdquo;</p>", Sterile.smart_format_tags(%q{<p>one<br>"two"</p>})
    assert_equal "<figure>one</figure>&ldquo;two&rdquo;", Sterile.smart_format_tags(%q{<figure>one</figure>"two"})
  end

  def test_smart_format_tags_reads_on_through_unknown_tags
    assert_equal "&ldquo;one<uppercase>!</uppercase>&rdquo;", Sterile.smart_format_tags(%q{"one<uppercase>!</uppercase>"})
  end

  def test_smart_format_tags_lists
    assert_equal "<ul>\n<li>one</li>\n<li>&ldquo;two&rdquo;</li>\n</ul>", Sterile.smart_format_tags(%q{<ul><li>one</li><li>"two"</li></ul>}).gsub("&#10;", "\n")
  end

  def test_smart_format_tags_leaves_markup_alone
    assert_equal %q{<a href="a--b?x=1&amp;y=2" title="it's">it&rsquo;s &ldquo;x&rdquo;&mdash;y</a>}, Sterile.smart_format_tags(%q{<a href="a--b?x=1&amp;y=2" title="it's">it's "x"--y</a>})
    assert_equal "AT&amp;T &lt;b&gt; 2&times;4 <em>x</em>", Sterile.smart_format_tags("AT&amp;T &lt;b&gt; 2x4 <em>x</em>")
    assert_equal "wait&hellip; <em>(c) 2020</em> (<em>tm</em>)", Sterile.smart_format_tags("wait... <em>(c) 2020</em> (<em>tm</em>)").sub("&copy;", "(c)")
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

  def test_quote_slash_quote
    assert_equal "“one”/“two”", Sterile.smart_format('"one"/"two"')
    assert_equal "‘one’/‘two’", Sterile.smart_format("'one'/'two'")
  end

  def test_number_single_quote
    assert_equal "War in ’24", Sterile.smart_format("War in '24")
  end

  def test_number_single_quote_in_double_quotes
    assert_equal "“War in ’24”", Sterile.smart_format("\"War in '24\"")
  end

  def test_copyright_symbol
    assert_equal "© 2016 PCG", Sterile.smart_format("(c) 2016 PCG")
    assert_equal "©2016", Sterile.smart_format("(c)2016")
    assert_equal "© 2016", Sterile.smart_format("(C) 2016")
    assert_equal "Copyright © PCG", Sterile.smart_format("Copyright (c) PCG")
    assert_equal "copyright © PCG", Sterile.smart_format("copyright (C) PCG")
  end

  def test_enumerated_c_is_not_copyright
    s = "(a) a king, (b) people, within (c) a territory, with (d) laws"
    assert_equal s, Sterile.smart_format(s)
    assert_equal "(c) the third point", Sterile.smart_format("(c) the third point")
  end

  def test_registered_symbol
    assert_equal "Acme® widgets", Sterile.smart_format("Acme(r) widgets")
    assert_equal "Acme®", Sterile.smart_format("Acme(R)")
  end

  def test_enumerated_r_is_not_registered
    s = "(q) one, (r) two"
    assert_equal s, Sterile.smart_format(s)
  end

end

