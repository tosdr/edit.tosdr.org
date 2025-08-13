# frozen_string_literal: true

require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

namespace :documents do
  desc 'Convert xpath to selector'
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

  # to-do: deprecate
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
        old_length = document.text.length
        old_crc = Zlib.crc32(@document.text)
      else
        old_length = 0
        old_crc = 0
      end

      new_crc = Zlib.crc32(@tbdoc.newdata)

      document.update(text: @tbdoc.newdata)
      new_length = document.text.length

      document_comment = DocumentComment.new
      document_comment.summary = '<span class="label label-info">Document has been crawled</span><br><b>Old length:</b> <kbd>' + old_length.to_s + ' CRC ' + old_crc.to_s + '</kbd><br><b>New length:</b> <kbd>' + new_length.to_s + ' CRC ' + new_crc.to_s + '</kbd>'
      document_comment.user_id = '21311'
      document_comment.document_id = document.id
      if document_comment.save
        puts 'Comment added!'
      else
        puts 'Error adding comment!'
        puts document_comment.errors.full_messages
      end
    end
  end
end
