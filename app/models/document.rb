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
    self.text = '' unless self.text

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []

    self.points.each do |p|
      if p.status === 'declined'
        next
      end

      if p.quote_text.nil? || (p.quote_start.nil? && p.quote_end.nil?)
        next
      end

      quote_exists_in_text = !self.text.index(p.quote_text).nil?

      if quote_exists_in_text
        quote_start = self.text.index(p.quote_text)
        quote_start_changed = p.quote_start != quote_start
        quote_end_changed = p.quote_end != p.quote_start + p.quote_text.length

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
      puts 'comparing ' + x.quote_start.to_s + ' to ' + y.quote_start.to_s
      x.quote_start - y.quote_start
    end

    quotes.each do |q|
      puts 'quote to snippet ' + q.quote_start.to_s + ' -> ' + q.quote_end.to_s + ' ..' + cursor.to_s
      if (q.quote_start > cursor)
        puts 'unquoted ' + cursor.to_s + ' -> ' + q.quote_start.to_s
        snippets.push({
          text: self.text[cursor, q.quote_start - cursor]
        })
        puts 'quoted ' + q.quote_start.to_s + ' -> ' + q.quote_end.to_s
        snippets.push({
          pointId: q.id,
          text: self.text[q.quote_start, q.quote_end - q.quote_start],
          title: q.title
        })
        puts 'cursor to ' + q.quote_end.to_s
        cursor = q.quote_end
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
