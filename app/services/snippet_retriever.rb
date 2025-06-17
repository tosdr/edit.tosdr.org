# frozen_string_literal: true

require 'fuzzystringmatch'

class SnippetRetriever
  def initialize(text:, points:)
    @text = text || ''
    @points = points
    @normalized_text = @text.gsub(/\s+/, ' ')
    @jarow = FuzzyStringMatch::JaroWinkler.create(:native)
    @match_threshold = 0.85
  end

  def call
    quotes = []
    snippets = []
    points_needing_restoration = []

    @points.each do |point|
      next if point.status == 'declined'
      next if point.quote_text.nil? || (point.quote_start.nil? && point.quote_end.nil?)

      normalized_quote = point.quote_text.gsub(/\s+/, ' ')
      quote_start = @normalized_text.index(normalized_quote)

      if quote_start.nil?
        quote_start = fuzzy_match(normalized_quote)
        if quote_start.nil?
          handle_not_found(point)
          next
        end
      end

      quote_end = quote_start + normalized_quote.length
      quote_start_changed = point.quote_start != quote_start
      quote_end_changed = point.quote_end != quote_end

      if point.status == 'approved-not-found'
        puts "✅ Point ##{point.id} restored. Status updated to 'approved'."
        point.status = 'approved'
        point.quote_start = quote_start
        point.quote_end = quote_end
        point.save!
        quotes << point
      elsif !quote_start_changed && !quote_end_changed
        quotes << point
      else
        puts "🛠️ Point ##{point.id} position mismatch. Old: #{point.quote_start}-#{point.quote_end}, New: #{quote_start}-#{quote_end}"
        points_needing_restoration << point
      end
    end

    snippets = extract_snippets(quotes)

    {
      snippets: snippets,
      points_needing_restoration: points_needing_restoration
    }
  end

  private

  def fuzzy_match(quote)
    best_match_index = nil
    best_score = 0.0
    window_size = quote.length

    (0..(@normalized_text.length - window_size)).each do |i|
      candidate = @normalized_text[i, window_size]
      score = @jarow.getDistance(quote, candidate)

      if score > best_score
        best_score = score
        best_match_index = i
      end
    end

    if best_score >= @match_threshold
      puts "🔍 Fuzzy match accepted with score #{best_score.round(3)}"
      best_match_index
    else
      nil
    end
  end

  def handle_not_found(point)
    puts "❌ No match for Point ##{point.id} (#{point.title})"
    if point.status == 'approved'
      point.status = 'approved-not-found'
      point.save!
    elsif point.status != 'approved-not-found'
      point.status = 'pending-not-found'
      point.save!
    end
  end

  def extract_snippets(quotes)
    snippets = []
    cursor = 0

    sorted = quotes.sort_by(&:quote_start)

    sorted.each do |q|
      next unless q.quote_start > cursor

      snippets << { text: @text[cursor, q.quote_start - cursor] }
      snippets << {
        pointId: q.id,
        text: @text[q.quote_start, q.quote_end - q.quote_start],
        title: q.title
      }

      cursor = q.quote_end
    end

    snippets << { text: @text[cursor, @text.length - cursor] }
    snippets
  end
end