# encoding: UTF-8

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


    def trim_whitespace(string)
      string.gsub(/\s+/, " ").strip
    end


    def sterilize(string)
      strip_tags(transliterate(string))
    end


    def sluggerize(string, options = {})
      options = {
        :delimiter => "-"
      }.merge!(options)

      sterile(string).strip.gsub(/\s+/, "-").gsub(/[^a-zA-Z0-9\-]/, "").gsub(/-+/, options[:delimiter]).downcase
    end


    def smart_format(string)
      SMART_FORMAT_RULES.each do |rule|
        string.gsub!(rule[0], rule[1])
      end
      string
    end


    def encode_entities(string)
      transmogrify(string) do |mapping, codepoint|
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


    def gsub_tags(string, &block)
      raise "No block given" unless block_given?

      string.gsub!(/(<[^>]*>)|([^<]+)/) do |match|
        $2 ? yield($2) : $1
      end
    end


    def scan_tags(string, &block)
      raise "No block given" unless block_given?

      string.scan(/(<[^>]*>)|([^<]+)/) do |match|
        yield($2) unless $2.nil?
      end
    end


    def smart_format_tags(string)
      string.gsub_tags do |text|
        text.smart_format.encode_entities
      end
    end


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

  end # class << self

end


class String
  Sterile.methods(false).each do |method|
    eval("def #{method}(*args, &block); Sterile.#{method}(self, *args, &block); end")
    eval("def #{method}!(*args, &block); replace Sterile.#{method}(self, *args, &block); end")
  end
end

