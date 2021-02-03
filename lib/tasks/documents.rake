require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

namespace :documents do
  desc "Recrawl all invalid documents"
  task recrawl: :environment do
    documents = Document.all
    documents.where('text is null').each do |document|
		@tbdoc = TOSBackDoc.new({
		  url: document.url,
		  xpath: document.xpath
		})

		@tbdoc.scrape
		
		if @tbdoc.apiresponse["error"]
			puts @tbdoc.apiresponse["message"]
			next
		end
		
		if not document.text.blank?
			oldLength = document.text.length
			oldCRC = Zlib::crc32(@document.text)
		else
			oldLength = 0
			oldCRC = 0
		end
		
		newCRC =  Zlib::crc32(@tbdoc.newdata)
		
		document.update(text: @tbdoc.newdata)
		newLength = document.text.length
		
		@document_comment = DocumentComment.new()
		@document_comment.summary = '<span class="label label-info">Document has been crawled</span><br><b>Old length:</b> <kbd>' + oldLength.to_s + ' CRC ' + oldCRC.to_s + '</kbd><br><b>New length:</b> <kbd>' + newLength.to_s + ' CRC ' + newCRC.to_s + '</kbd>'
		@document_comment.user_id = "21311"
		@document_comment.document_id = document.id
		if @document_comment.save
		  puts "Comment added!"
		else
			puts "Error adding comment!"
			puts @document_comment.errors.full_messages
		end
    end
  end
end