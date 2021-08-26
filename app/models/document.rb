class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service
  belongs_to :user, optional: true

  has_many :points
  has_many :document_comments, dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true
  validates :service_id, presence: true

  validate :custom_uniqueness_check

  def custom_uniqueness_check
    doc = Document.where(url: self.url, xpath: self.xpath, status: nil)
    if doc.any? && (doc.first.id != self.id)
      go_to_doc = Rails.application.routes.url_helpers.document_url(doc.first.id)
      self.errors.add(:url, "A document for this URL already exists! Inspect it here: #{go_to_doc}")
    end
  end

  def self.search_by_document_name(query)
    Document.joins(:service).where("services.name ILIKE ? or documents.name ILIKE ? or documents.url ILIKE?", "%#{query}%", "%#{query}%", "%#{query}%")
  end

  def snippets
    if (!self.text)
      self.text = ''
    end

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []

    self.points.each do |p|
      if p.status === 'declined'
        next
      end

      if p.quoteText.nil?
        next
      end

      quote_exists_in_text = !self.text.index(p.quoteText).nil?

      if quote_exists_in_text
        quote_start = self.text.index(p.quoteText)
        quote_start_changed = p.quoteStart != quote_start
        quote_end_changed = p.quoteEnd != p.quoteStart + p.quoteText.length

        if (!quote_start_changed && !quote_end_changed)
          # quote is okay, so we store it
          quotes << p
        else
          points_with_quote_text_to_restore_in_doc << p
        end
      end
    end

    cursor = 0

    quotes.sort! do |x, y|
      puts 'comparing ' + x.quoteStart.to_s + ' to ' + y.quoteStart.to_s
      x.quoteStart - y.quoteStart
    end

    quotes.each do |q|
      puts 'quote to snippet ' + q.quoteStart.to_s + ' -> ' + q.quoteEnd.to_s + ' ..' + cursor.to_s
      if (q.quoteStart > cursor)
        puts 'unquoted ' + cursor.to_s + ' -> ' + q.quoteStart.to_s
        snippets.push({
          text: self.text[cursor, q.quoteStart - cursor]
        })
        puts 'quoted ' + q.quoteStart.to_s + ' -> ' + q.quoteEnd.to_s
        snippets.push({
          pointId: q.id,
          text: self.text[q.quoteStart, q.quoteEnd - q.quoteStart],
          title: q.title
        })
        puts 'cursor to ' + q.quoteEnd.to_s
        cursor = q.quoteEnd
      end
    end

    puts 'final snippet ' + cursor.to_s + ' -> ' + self.text.length.to_s

    snippets.push({
      text: self.text[cursor, self.text.length - cursor]
    })

    {
      snippets: snippets,
      points_needing_restoration: points_with_quote_text_to_restore_in_doc
    }
  end
end
