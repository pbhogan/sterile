# encoding: UTF-8

module Sterile
  # @private
  class Data
    def self.smart_format_rules
      [
        ["'tain't", "’tain’t"],
        ["'twere", "’twere"],
        ["'twas", "’twas"],
        ["'tis", "’tis"],
        ["'twill", "’twill"],
        ["'Tain't", "’Tain’t"],
        [/\'(Tis|Twas|Twill|Twere)\b/, "’\\1"],
        ["'til", "’til"],
        ["'bout", "’bout"],
        ["'nuff", "’nuff"],
        ["'round", "’round"],
        ["'cause", "’cause"],
        ["'cos", "’cos"],
        ["i'm", "i’m"],
        # The Afrikaans article ("'n man"), and "rock 'n roll".
        [/\'n(?=[\p{Z}\s])/, "’n"],
        # Not three hyphens ("h---"); a longer run still pairs off.
        [/(?<!-)--(?!-(?!-))|(?<=--)--/, "—"],
        ["...", "…"],
        # A quote after a dash opens (word--"quote"), unless a space, closing
        # punctuation, another dash or the end follows ("Why--" he said).
        [/([—–])"(?![\p{Z}\s,;:!?)\]—–]|\.(?![\p{Z}\s]?\.)|\z)/, "\\1“"],
        [/([—–])\'(?![\p{Z}\s,;:!?)\]—–\d]|\.(?![\p{Z}\s]?\.)|\z)/, "\\1‘"],
        ["(tm)", "™"],
        ["(TM)", "™"],
        # Only where it's clearly a copyright notice, so list markers like
        # "(a) … (b) … (c) …" survive.
        [/\([cC]\)(?=[\p{Z}\s]*\d)/, "©"],
        [/(copyright[\p{Z}\s]+)\([cC]\)/i, "\\1©"],
        # Only when attached to the preceding word (e.g. "Acme(R)").
        [/(?<=[^\p{Z}\s(])\([rR]\)/, "®"],
        ['"/"', "”/“"],
        ["'/'", "’/‘"],
        [/([iI][nN]\s+)\'(\d\d\D)/, "\\1’\\2"],
        [/([iI][nN]\s+)\'(\d\d)$/, "\\1’\\2"],
        [/\'(\d\d)(?!’|\'|[^’\'\s]+[’\'][\p{P}\p{Z}])([\p{P}\p{Z}])/, "’\\1\\2"],
        # [/<p>"/, "<p>\\1″"],
        [/s\'([^a-zA-Z0-9])/, "s’\\1"],
        [/"([:;])/, "”\\1"],
        [/\'s$/, "’s"],
        [/\'(\d\d(?:’|\')?s)/, "’\\1"],
        # A quote opens after a space, a non-breaking one included.
        [/([\p{Z}\s]|&nbsp;|\A|"|\(|\[)\'/, "\\1‘"],
        # [/(\d+)"/, "\\1″"],
        # [/(\d+)\'/, "\\1′"],
        [/(\S)\'([^\'\s])/, "\\1’\\2"],
        [/([\p{Z}\s]|&nbsp;|\A|\(|\[)"(?![\p{Z}\s]|&nbsp;)/, "\\1“"],
        [/"(\s|\S|\Z)/, "”\\1"],
        [/\'([\s.]|\Z)/, "’\\1"],
        [/(\b[1-9]\d*|0)x([1-9]\d*|0\b)/, "\\1×\\2"],
        [/([a-z])'(t|d|s|ll|re|ve)(\b)/i, "\\1’\\2\\3"],
      ]
    end
  end
end
