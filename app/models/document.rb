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
    self.points.each do |p|
      if (p.status === 'declined') then
        next;
      end
      quoteStart = self.text.index(p.quoteText)
      if (p.quoteStart == quoteStart && p.quoteEnd == p.quoteStart + p.quoteText.length)
        puts 'quote ok! ' + p.quoteStart.to_s + '->' + p.quoteEnd.to_s + ': ' + p.quoteText
        quotes << p
      else
        if quoteStart
          puts 'quote not found! [' + p.quoteStart.to_s + '==' + quoteStart.to_s + '][' + p.quoteEnd.to_s + '==' + (quoteStart + p.quoteText.length).to_s + ']'
          puts '-----'
          puts p.quoteText
          puts '-----'
          puts self.text[p.quoteStart, p.quoteEnd]
          puts '-----'
          puts self.text.index(self.text[p.quoteStart, p.quoteEnd])
          puts '-----'
          puts '-----'
          puts self.text.index(p.quoteText)
          puts '-----'
          puts '-----'
        else
          puts 'no quoteStart found!'
        end
      end
    end
    cursor = 0
    quotes.sort! do |x,y|
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
      else
        puts 'skipping empty'
      end
    end
    puts 'final snippet ' + cursor.to_s + ' -> ' + self.text.length.to_s
    snippets.push({
      text: self.text[cursor, self.text.length - cursor]
    })
    snippets
  end
end
