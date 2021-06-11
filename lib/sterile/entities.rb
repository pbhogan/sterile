# encoding: UTF-8

module Sterile

  class << self

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

    DECODE_ENTITIES_RE = /
      &(?:
        \#(\d{1,7})|           # base 10
        \#x([a-fA-F0-9]{1,7})| # base 16
        ([a-zA-Z0-9]+)         # text
      );/x

    # The reverse of +encode_entities+. Turns HTML or numeric entities into
    # their Unicode counterparts.
    #
    def decode_entities(string)
      return string if !string.include?("&")

      string.gsub(DECODE_ENTITIES_RE) do
        if $1
          $1.to_i.chr(Encoding::UTF_8)
        elsif $2
          $2.to_i(16).chr(Encoding::UTF_8)
        elsif $3
          codepoint = html_entities_data[$3]
          codepoint ? codepoint.chr(Encoding::UTF_8) : $&
        end
      end
    end

    private

    # Lazy load html entities
    #
    def html_entities_data
      @html_entities_data ||= begin
        require "sterile/data/html_entities_data"
        Data.html_entities_data
      end
    end

  end # class << self

end # module Sterile
