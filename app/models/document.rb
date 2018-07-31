class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :service_id, presence: true

  def self.search_by_document_name(query)
    Document.where("name ILIKE ?", "%#{query}%")
  end
  def snippets
    if (!self.text)
      self.text = ''
    end
    quotes = []
    snippets = []
    self.points.each do |p|
      quoteStart = self.text.index(p.quoteText)
      if (p.quoteStart == quoteStart && p.quoteEnd == p.quoteStart + p.quoteText.length)
        puts 'quote ok! ' + p.quoteStart.to_s + '->' + p.quoteEnd.to_s + ': ' + p.quoteText
        quotes << p
      else
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
          text: self.text[q.quoteStart, q.quoteEnd - q.quoteStart]
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

  def points
    Point.where('"service_id" = ?', self.service_id).where('"quoteDoc" = ?', self.name)
  end
end
