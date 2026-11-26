# frozen_string_literal: true

require 'strscan'

# Finds where a point's quote sits in a document's text. Always answers with character offsets
# into the raw stored text (HTML included) -- what quote_start / quote_end refer to -- never into
# the normalized copy used for matching. Tried in order:
#
#   1. the stored location, if the quote is still exactly there;
#   2. anywhere else in the text, exact (first occurrence);
#   3. ignoring HTML tags, whitespace and letter case: every visible character must match, but
#      markup, spacing and capitalization may have changed.
#
# Build one locator per text and reuse it across that text's points: the normalized copy of the
# text is computed once, and only if some quote needs step 3.
class QuoteLocator
  # Skipped when normalizing: HTML tags, and whitespace (including non-breaking spaces).
  IGNORED = /<[^>]*>|(?:[[:space:]]|&nbsp;)+/i

  def initialize(text)
    @text = text.to_s
  end

  # Returns the quote's location as an exclusive Range of raw-text offsets, or nil when the
  # quote isn't in the text.
  def locate(quote, stored_start: nil)
    return nil if quote.blank?

    if stored_start && @text[stored_start, quote.length] == quote
      return stored_start...(stored_start + quote.length)
    end

    exact = @text.index(quote)
    return exact...(exact + quote.length) if exact

    locate_normalized(quote)
  end

  # The visible characters of `raw`, downcased, plus the raw offset each one came from.
  def self.normalize(raw)
    chars = +''
    offsets = []
    scanner = StringScanner.new(raw)

    until scanner.eos?
      next if scanner.skip(IGNORED)

      offset = scanner.charpos
      scanner.getch.downcase.each_char do |char|
        chars << char
        offsets << offset
      end
    end

    [chars, offsets]
  end

  private

  def locate_normalized(quote)
    needle, = self.class.normalize(quote)
    return nil if needle.empty?

    haystack, offsets = normalized_text
    found = haystack.index(needle)
    return nil unless found

    # Map the first and last matched characters back to the raw text. The range ends right
    # after the last visible character, so a tag that used to close the quote is left out.
    offsets[found]...(offsets[found + needle.length - 1] + 1)
  end

  def normalized_text
    @normalized_text ||= self.class.normalize(@text)
  end
end
