# encoding: UTF-8

# Copyright (c) 2011 Patrick Hogan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "sterile/codepoints"
require "sterile/html_entities"
require "sterile/smart_format_rules"


module Sterile

  class << self

    def transmogrify(string, &block)
      raise "No block given" unless block_given?

      result = ""
      string.unpack("U*").each do |codepoint|
        cg = codepoint >> 8
        cp = codepoint & 0xFF
        begin
          mapping = CODEPOINTS[cg][cp]
          result << yield(mapping, codepoint)
        rescue
        end
      end

      result
    end

    # Transliterate Unicode [and accented ASCII] characters to their plain-text
    # ASCII equivalents. This is based on data from the stringex gem (https://github.com/rsl/stringex)
    # which is in turn a port of Perl's Unidecode and ostensibly provides
    # superior results to iconv. The optical conversion data is based on work
    # by Eric Boehs at https://github.com/ericboehs/to_slug
    # Passing an option of :optical => true will prefer optical mapping instead
    # of more pedantic matches.
    #
    #   "ýůçký".transliterate # => "yucky"
    #
    def transliterate(string, options = {})
      options = {
        :optical => false
      }.merge!(options)

      if options[:optical]
        transmogrify(string) do |mapping, codepoint|
          mapping[1] || mapping[0] || ""
        end
      else
        transmogrify(string) do |mapping, codepoint|
          mapping[0] || mapping[1] || ""
        end
      end
    end
    alias_method :to_ascii, :transliterate


    # Trim whitespace from start and end of string and remove any redundant
    # whitespace in between.
    #
    #   " Hello  world! ".transliterate # => "Hello world!"
    #
    def trim_whitespace(string)
      string.gsub(/\s+/, " ").strip
    end


    # Transliterate to ASCII and strip out any HTML/XML tags.
    #
    #   "<b>nåsty</b>".sterilize # => "nasty"
    #
    def sterilize(string)
      strip_tags(transliterate(string))
    end


    # Transliterate to ASCII, downcase and format for URL permalink/slug
    # by stripping out all non-alphanumeric characters and replacing spaces
    # with a delimiter (defaults to '-').
    #
    #   "Hello World!".sluggerize # => "hello-world"
    #
    def sluggerize(string, options = {})
      options = {
        :delimiter => "-"
      }.merge!(options)

      sterilize(string).strip.gsub(/\s+/, "-").gsub(/[^a-zA-Z0-9\-]/, "").gsub(/-+/, options[:delimiter]).downcase
    end
    alias_method :to_slug, :sluggerize


    # Format text with proper "curly" quotes, m-dashes, copyright, trademark, etc.
    #
    #   q{"He said, 'Away with you, Drake!'"}.smart_format # => “He said, ‘Away with you, Drake!’”
    #
    def smart_format(string)
      SMART_FORMAT_RULES.each do |rule|
        string.gsub!(rule[0], rule[1])
      end
      string
    end


    # Turn Unicode characters into their HTML equivilents.
    # If a valid HTML entity is not possible, it will create a numeric entity.
    #
    #   q{“Economy Hits Bottom,” ran the headline}.encode_entities # => &ldquo;Economy Hits Bottom,&rdquo; ran the headline
    #
    def encode_entities(string)
      transmogrify(string) do |mapping, codepoint|
        if (32..126).include?(codepoint)
          mapping[0]
        else
          "&" + (mapping[2] || "#" + codepoint.to_s) + ";"
        end
      end
    end


    # The reverse of +encode_entities+. Turns HTML or numeric entities into
    # their Unicode counterparts.
    #
    def decode_entities(string)
      string.gsub!(/&#(\d{1,4});/) { [$1.to_i].pack("U") }
      string.gsub(/&([a-zA-Z0-9]+);/) do
        codepoint = HTML_ENTITIES[$1]
        codepoint ? [codepoint].pack("U") : $&
      end
    end


    # Remove HTML/XML tags from text. Also strips out comments, PHP and ERB style tags.
    # CDATA is considered text unless :keep_cdata => false is specified.
    # Redundant whitespace will be removed unless :keep_whitespace => true is specified.
    #
    def strip_tags(string, options = {})
      options = {
        :keep_whitespace => false,
        :keep_cdata      => true
      }.merge!(options)

      string.gsub!(/<[%?](php)?[^>]*>/, '') # strip php, erb et al
      string.gsub!(/<!--[^-]*-->/, '')      # strip comments

      string.gsub!(
        /
          <!\[CDATA\[
          ([^\]]*)
          \]\]>
        /xi,
        options[:keep_cdata] ? '\\1' : ''
      )

      html_name = /[\w:-]+/
      html_data = /([A-Za-z0-9]+|('[^']*?'|"[^"]*?"))/
      html_attr = /(#{html_name}(\s*=\s*#{html_data})?)/

      string.gsub!(
        /
          <
          [\/]?
          #{html_name}
          (\s+(#{html_attr}(\s+#{html_attr})*))?
          \s*
          [\/]?
          >
        /xi,
        ''
      )

      options[:keep_whitespace] ? string : trim_whitespace(string)
    end


    # Similar to +gsub+, except it works in between HTML/XML tags and 
    # yields text to a block. Text will be replaced by what the block
    # returns.
    # Warning: does not work in some degenerate cases.
    #
    def gsub_tags(string, &block)
      raise "No block given" unless block_given?

      string.gsub!(/(<[^>]*>)|([^<]+)/) do |match|
        $2 ? yield($2) : $1
      end
    end


    # Iterates over all text in between HTML/XML tags and yields
    # it to a block.
    # Warning: does not work in some degenerate cases.
    #
    def scan_tags(string, &block)
      raise "No block given" unless block_given?

      string.scan(/(<[^>]*>)|([^<]+)/) do |match|
        yield($2) unless $2.nil?
      end
    end


    # Like +smart_format+, but works with HTML/XML (somewhat).
    #
    def smart_format_tags(string)
      string.gsub_tags do |text|
        text.smart_format.encode_entities
      end
    end


    # Format text appropriately for titles. This method is much smarter
    # than ActiveSupport's +titlecase+. The algorithm is based on work done
    # by John Gruber et al (http://daringfireball.net/2008/08/title_case_update)
    #
    def titlecase(string)
      string.strip!
      string.gsub!(/\s+/, " ")
      string.downcase! unless string =~ /[[:lower:]]/

      small_words = %w{ a an and as at(?!&t) but by en for if in nor of on or the to v[.]? via vs[.]? }.join("|")
      apos = / (?: ['’] [[:lower:]]* )? /xu

      string.gsub!(
        /
          \b
          ([_\*]*)
          (?:
            ( [-\+\w]+ [@.\:\/] [-\w@.\:\/]+ #{apos} )      # URL, domain, or email
            |
            ( (?i: #{small_words} ) #{apos} )               # or small word, case-insensitive
            |
            ( [[:alpha:]] [[:lower:]'’()\[\]{}]* #{apos} )  # or word without internal caps
            |
            ( [[:alpha:]] [[:alpha:]'’()\[\]{}]* #{apos} )  # or some other word
          )
          ([_\*]*)
          \b
        /xu
      ) do
        ($1 ? $1 : "") +
        ($2 ? $2 : ($3 ? $3.downcase : ($4 ? $4.downcase.capitalize : $5))) +
        ($6 ? $6 : "")
      end

      if RUBY_VERSION < "1.9.0"
        string.gsub!(
          /
            \b
            ([:alpha:]+)
            (‑)
            ([:alpha:]+)
            \b
          /xu
        ) do
          $1.downcase.capitalize + $2 + $1.downcase.capitalize
        end
      end

      string.gsub!(
        /
          (
            \A [[:punct:]]*     # start of title
            | [:.;?!][ ]+       # or of subsentence
            | [ ]['"“‘(\[][ ]*  # or of inserted subphrase
          )
          ( #{small_words} )    # followed by a small-word
          \b
        /xiu
      ) do
        $1 + $2.downcase.capitalize
      end

      string.gsub!(
        /
          \b
          ( #{small_words} )    # small-word
          (?=
            [[:punct:]]* \Z     # at the end of the title
            |
            ['"’”)\]] [ ]       # or of an inserted subphrase
          )
        /xu
      ) do
        $1.downcase.capitalize
      end

      string.gsub!(
        /
          (
            \b
            [[:alpha:]]         # single first letter
            [\-‑]               # followed by a dash
          )
          ( [[:alpha:]] )       # followed by a letter
        /xu
      ) do
        $1 + $2.downcase
      end

      string.gsub!(/q&a/i, 'Q&A')

      string
    end

  end

end


# Add extensions to String
#
class String
  Sterile.methods(false).each do |method|
    eval("def #{method}(*args, &block); Sterile.#{method}(self, *args, &block); end")
    eval("def #{method}!(*args, &block); replace Sterile.#{method}(self, *args, &block); end")
  end
end

