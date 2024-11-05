require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

namespace :documents do
  desc 'Pull document text from OTA github'
  task fetch_ota_text: :environmnet do
    documents = Document.includes(:service).all
    documents.each(&:fetch_ota_text)
  end

  task validate_selector: :environment do
    documents = Document.all
    documents.each do |document|
      next unless document.selector.present?

      runner = NodeRunner.new(
        <<~JAVASCRIPT
               const xPathToCss = require('xpath-to-css')
               const convert = (selector) => {
          try {
          	const css = xPathToCss(selector)
          	return css;
          } catch (error) {
               			return 'body';
                 }
               }
        JAVASCRIPT
      )
      new_selector = runner.convert document.selector
      document.selector = new_selector
      document.save!
    end
  end

  desc 'Recrawl all invalid documents'
  task recrawl: :environment do
    documents = Document.all
    documents.where('text is null').each do |document|
      @tbdoc = TOSBackDoc.new({
                                url: document.url,
                                xpath: document.xpath
                              })

      @tbdoc.scrape

      if @tbdoc.apiresponse['error']
        puts @tbdoc.apiresponse['message']
        next
      end

      if !document.text.blank?
        oldLength = document.text.length
        oldCRC = Zlib.crc32(@document.text)
      else
        oldLength = 0
        oldCRC = 0
      end

      newCRC = Zlib.crc32(@tbdoc.newdata)

      document.update(text: @tbdoc.newdata)
      newLength = document.text.length

      @document_comment = DocumentComment.new
      @document_comment.summary = '<span class="label label-info">Document has been crawled</span><br><b>Old length:</b> <kbd>' + oldLength.to_s + ' CRC ' + oldCRC.to_s + '</kbd><br><b>New length:</b> <kbd>' + newLength.to_s + ' CRC ' + newCRC.to_s + '</kbd>'
      @document_comment.user_id = '21311'
      @document_comment.document_id = document.id
      if @document_comment.save
        puts 'Comment added!'
      else
        puts 'Error adding comment!'
        puts @document_comment.errors.full_messages
      end
    end
  end
end
