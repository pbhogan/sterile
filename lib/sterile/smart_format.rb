# encoding: UTF-8

module Sterile

  class << self

    # Format text with proper "curly" quotes, m-dashes, copyright, trademark, etc.
    #
    #   q{"He said, 'Away with you, Drake!'"}.smart_format # => “He said, ‘Away with you, Drake!’”
    #
    def smart_format(string)
      string = string.to_s
      string = string.dup if string.frozen?
      smart_format_rules.each do |rule|
        string.gsub! rule[0], rule[1]
      end
      string
    end


    # Like +smart_format+, but works with HTML/XML (somewhat). Quotes and
    # apostrophes are formatted by the text on either side of them, across
    # inline tags ("<em>Bible</em>'s"), starting over in each block and
    # after a line break.
    #
    def smart_format_tags(string)
      string = string.gsub(/[\p{Z}\s]+(<\/[a-zA-Z]+>)(['"][a-zA-Z])/, "\\1 \\2") # Fixes quote after whitespace + tag "<em>Dan. </em>'And"
      fragment = Nokogiri::HTML::DocumentFragment.parse string
      smart_format_text_runs(fragment).each do |run|
        texts = run.map(&:content)
        run.each_with_index do |node, index|
          before = texts[0...index].reverse.find { |text| !text.empty? }
          after = texts[(index + 1)..-1].find { |text| !text.empty? }
          node.content = smart_format_in_context(texts[index], before, after)
        end
      end
      fragment.to_html.encode_entities
    end


    private

    # Elements that start a new stretch of text. Text in any other element,
    # known or not, reads on from the text before it.
    SMART_FORMAT_BLOCK_TAGS = %w[
      address article aside blockquote body br caption center dd details dialog dir div dl dt fieldset
      figcaption figure footer form h1 h2 h3 h4 h5 h6 header hgroup hr html li main menu nav ol p pre
      section summary table tbody td tfoot th thead title tr ul
    ].freeze

    # Stands in for neighboring text no rule should treat as a space, a letter
    # or punctuation (a word joiner).
    SMART_FORMAT_NEUTRAL = "\u2060".freeze


    # Text nodes in document order, grouped into runs that read as continuous
    # text: a run ends at a block element or a line break.
    #
    def smart_format_text_runs(node, runs = [[]])
      node.children.each do |child|
        if child.text?
          runs.last << child
        elsif child.element? && SMART_FORMAT_BLOCK_TAGS.include?(child.name)
          runs << []
          smart_format_text_runs child, runs
          runs << []
        elsif child.element?
          smart_format_text_runs child, runs
        end
      end
      runs
    end


    # Smart format text that sits between two other pieces of text. One
    # character stands in for each neighbor while the rules run.
    #
    def smart_format_in_context(text, before, after)
      head = smart_format_stand_in_before(before)
      tail = smart_format_stand_in_after(after)
      formatted = smart_format("#{head}#{text}#{tail}")
      if formatted.start_with?(head) && formatted.end_with?(tail) && formatted.length >= head.length + tail.length
        formatted[head.length, formatted.length - head.length - tail.length]
      else
        smart_format(text.dup)
      end
    end


    def smart_format_stand_in_before(text)
      case text
      when nil then ""
      when /(?:--|[—–])\z/ then "—"
      when /[\p{Z}\s]\z/ then " "
      when /[(\[{"“]\z/ then "["
      when /[\p{L}\p{N}]\z/ then text[-1]
      else SMART_FORMAT_NEUTRAL
      end
    end


    def smart_format_stand_in_after(text)
      case text
      when nil then ""
      when /\A[\p{Z}\s]/ then " "
      when /\A\p{L}/ then "a" # Any letter will do, but "s" would end the "'s" rule.
      when /\A[\p{N}:;]/ then text[0]
      when /\A(?:[,!?)\]}]|\.(?![\p{Z}\s]?\.))/ then ","
      else SMART_FORMAT_NEUTRAL
      end
    end


    # Lazy load smart formatting rules
    #
    def smart_format_rules
      @smart_format_rules ||= begin
        require "sterile/data/smart_format_rules"
        Data.smart_format_rules
      end
    end

  end # class << self

end # module Sterile

