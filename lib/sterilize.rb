# encoding: UTF-8

require "sterilize/codepoints"
require "sterilize/html_entities"


module Sterilize

  class << self

    def convert(string, &strategy)
      raise "Must provide block for strategy parameter" unless block_given?

      new_string = ""
      string.unpack("U*").each do |codepoint|
        cg = codepoint >> 8
        cp = codepoint & 0xFF
        begin
          mapping = CODEPOINTS[cg][cp]
          new_string << yield(mapping, codepoint)
        rescue
          new_string << ""
        end
      end

      new_string
    end


    def transliterate(string, options = {})
      options = {
        :optical => false
      }.merge!(options)

      if options[:optical]
        convert(string) do |mapping, codepoint|
          mapping[1] || mapping[0] || ""
        end
      else
        convert(string) do |mapping, codepoint|
          mapping[0] || mapping[1] || ""
        end
      end
    end


    def encode_entities(string)
      convert(string) do |mapping, codepoint|
        if (32..126).include?(codepoint)
          mapping[0]
        else
          "&" + (mapping[2] || "#" + codepoint.to_s) + ";"
        end
      end
    end


    def decode_entities(string)
      string.gsub!(/&#(\d{1,4});/) { [$1.to_i].pack("U") }
      string.gsub(/&([a-zA-Z0-9]+);/) do
        codepoint = HTML_ENTITIES[$1]
        codepoint ? [codepoint].pack("U") : $&
      end
    end


    def trim_whitespace(string)
      string.gsub(/\s+/, " ").strip
    end


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


    def sterilize(string)
      strip_tags(transliterate(string))
    end


    def sluggerize(string, options = {})
      options = {
        :delimiter => "-"
      }.merge!(options)

      sterilize(string).strip.gsub(/\s+/, "-").gsub(/[^a-zA-Z0-9\-]/, "").gsub(/-+/, options[:delimiter]).downcase
    end


    def smart_format(string)
      {
        "'tain't" => "’tain’t",
        "'twere" => "’twere",
        "'twas" => "’twas",
        "'tis" => "’tis",
        "'twill" => "’twill",
        "'til" => "’til",
        "'bout" => "’bout",
        "'nuff" => "’nuff",
        "'round" => "’round",
        "'cause" => "’cause",
        "'cos" => "’cos",
        "i'm" => "i’m",
        '--"' => "—”",
        "--'" => "—’",
        "--" => "—",
        "..." => "…",
        "(tm)" => "™",
        "(TM)" => "™",
        "(c)" => "©",
        "(r)" => "®",
        "(R)" => "®",
        /s\'([^a-zA-Z0-9])/ => "s’\\1",
        /"([:;])/ => "”\\1",
        /\'s$/ => "’s",
        /\'(\d\d(?:’|\')?s)/ => "’\\1",
        /(\s|\A|"|\(|\[)\'/ => "\\1‘",
        /(\d+)"/ => "\\1′",
        /(\d+)\'/ => "\\1″",
        /(\S)\'([^\'\s])/ => "\\1’\\2",
        /(\s|\A|\(|\[)"(?!\s)/ => "\\1“\\2",
        /"(\s|\S|\Z)/ => "”\\1",
        /\'([\s.]|\Z)/ => "’\\1",
        /(\d+)x(\d+)/ => "\\1×\\2",
        /([a-z])'(t|d|s|ll|re|ve)(\b)/i => "\\1’\\2\\3"
      }.each { |rule, replacement| string.gsub!(rule, replacement) }

      string
    end


    def smart_format_html(string)
      string.gsub_text { |text| text.smart_format.encode_entities }
    end


    def gsub_text(string, &block)
      raise "No block given" unless block_given?

      string.gsub!(/(<[^>]*>)|([^<]+)/) do |match|
        $2 ? yield($2) : $1
      end
    end


    def scan_text(string, &block)
      raise "No block given" unless block_given?

      string.scan(/(<[^>]*>)|([^<]+)/) do |match|
        yield($2) unless $2.nil?
      end
    end


    def titlecase(string)
      string.strip!
      string.gsub!(/\s+/, " ")
      string.downcase! unless string =~ /[[:lower:]]/

      small_words = %w{ (?<!q&)a an and as at(?!&t) but by en for if in nor of on or the to v[.]? via vs[.]? }.join("|")
      apos = / (?: ['’] [[:lower:]]* )? /x

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
        /x
      ) do
        # $1 + (
        #   $2 ? $2               # preserve URL, domain, or email
        #   : $3 ? $3.downcase    # lowercase small word
        #   : $4 ? $4.downcase.capitalize # capitalize word w/o internal caps
        #   : $5                  # preserve other kinds of word
        # ) + $6
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
        /xi
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
        /x
      ) do
        $1.downcase.capitalize
      end

      string.gsub!(
        /
          (
            \b
            [[:alpha:]]         # single first letter
            \-                  # followed by a dash
          )
          ( [[:alpha:]] )       # followed by a letter
        /x
      ) do
        $1 + $2.downcase
      end

      string
    end

  end # class << self

end


# module StringExtensions
#   def self.included(base)
#     Sterilize.methods(false).each do |method|
#       base.send(:define_method, method) do |*args|
#         Sterilize.send(method, self, *args)
#       end
#     end
#   end
# end
# String.send :include, Sterilize::StringExtensions


class String
  Sterilize.methods(false).each do |method|
    eval("def #{method}(*args, &block); Sterilize.#{method}(self, *args, &block); end")
    eval("def #{method}!(*args, &block); replace Sterilize.#{method}(self, *args, &block); end")
  end
end

