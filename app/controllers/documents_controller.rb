require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

puts 'loaded?'
puts TOSBackDoc

class DocumentsController < ApplicationController
  include Pundit

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_document, only: [:show, :edit, :update, :crawl]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Document

    if @query = params[:query]
      @documents = Document.includes(:service).search_by_document_name(@query)
    else
      @documents = Document.includes(:service).all
    end
  end

  def new
    authorize Document

    @document = Document.new
    if service = params[:service]
      @document.service = Service.find(service)
    end
  end

  def create
    authorize Document

    @document = Document.new(document_params)
    @document.user = current_user

    if @document.save
      perform_crawl
      if @document.text.blank?
        flash[:alert] = "It seems that our crawler wasn't able to retrieve any text. Please check that the XPath and URL are accurate."
        redirect_to document_path(@document)
      else
        redirect_to document_path(@document)
      end
    else
      render 'new'
    end
  end

  def update
    authorize @document

    @document.update(document_params)

    # we should probably only be running the crawler if the URL or XPath have changed
    if @document.saved_changes.keys.any? { |attribute| ["url", "xpath", "crawler_server"].include? attribute }
      crawlresult = perform_crawl
    end

    if @document.save
      # only want to do this if XPath or URL have changed - the theory is that text is returned blank when there's a defunct URL or XPath to avoid server error upon 404 error in the crawler
      # need to alert people if the crawler wasn't able to retrieve any text...
	  
      if crawlresult != nil
		if crawlresult["error"]
			flash[:alert] = "It seems that our crawler wasn't able to retrieve any text. Please check that the XPath and URL are accurate.<br><br>Reason: "+ crawlresult["message"]["name"].to_s + "<br>Stacktrace: "+ CGI.escapeHTML(crawlresult["message"]["remoteStacktrace"].to_s)
			redirect_to document_path(@document)
		else
			flash[:notice] = "The crawler has updated the document<br><a href='"+crawlresult["imageurl"]+"' target='_blank'><img src='"+crawlresult["imageurl"]+"' width='128'></a>"
			redirect_to document_path(@document)
		end
	  else
		redirect_to document_path(@document)
	  end
    else
      render 'edit'
    end
  end

  def destroy
    @document = Document.find(params[:id] || params[:document_id])
    authorize @document

    service = @document.service
    if @document.points.any?
      flash[:alert] = "Users have highlighted points in this document; update or delete those points before deleting this document."
      redirect_to document_path(@document)
    else
      @document.destroy
      redirect_to annotate_path(service)
    end
  end

  def show
    authorize @document
  end

  def crawl
    authorize @document
	crawlresult = perform_crawl
    if crawlresult["error"]
	  flash[:alert] = "It seems that our crawler wasn't able to retrieve any text. Please check that the XPath and URL are accurate.<br><br>Reason: "+ crawlresult["message"]["name"].to_s + "<br>Stacktrace: "+ CGI.escapeHTML(crawlresult["message"]["remoteStacktrace"].to_s)
	  redirect_to document_path(@document)
	else
	flash[:notice] = "The crawler has updated the document"
	redirect_to document_path(@document)
	end
  end

  private

  def user_not_authorized
    flash[:info] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:service, :service_id, :user_id, :name, :url, :xpath, :crawler_server)
  end

  def perform_crawl
    authorize @document

    @tbdoc = TOSBackDoc.new({
      url: @document.url,
      xpath: @document.xpath,
	  server: @document.crawler_server
    })

    @tbdoc.scrape
	
	if @tbdoc.apiresponse["error"]
		return @tbdoc.apiresponse
	end
	
	if not @document.text.blank?
		oldLength = @document.text.length
		oldCRC = Zlib::crc32(@document.text)
	else
		oldLength = 0
		oldCRC = 0
	end
	newCRC =  Zlib::crc32(@tbdoc.newdata)
	
	if oldCRC == newCRC
		@tbdoc.apiresponse["error"] = true
		@tbdoc.apiresponse["message"]["name"] = "The source document has not been updated. No changes made."
		@tbdoc.apiresponse["message"]["remoteStacktrace"] = "SourceDocument"
		return @tbdoc.apiresponse
	else
		@document.update(text: @tbdoc.newdata)
		newLength = @document.text.length
		

		# There is a cron job in the crontab of the 'tosdr' user on the forum.tosdr.org
		# server which runs once a day and before it deploys the site from edit.tosdr.org
		# to tosdr.org, it will run the check_quotes script from
		# https://github.com/tosdr/tosback-crawler/blob/225a74b/src/eto-admin.js#L121-L123
		# So that if text has moved without changing, points are updated to the corrected
		# quoteStart, quoteEnd, and quoteText values where possible, and/or their status is
		# switched between:
		# pending <-> pending-not-found
		# approved <-> approved-not-found
		@document_comment = DocumentComment.new()
		@document_comment.summary = '<span class="label label-info">Document has been crawled</span><br><b>Old length:</b> <kbd>' + oldLength.to_s + ' CRC ' + oldCRC.to_s + '</kbd><br><b>New length:</b> <kbd>' + newLength.to_s + ' CRC ' + newCRC.to_s + '</kbd>'
		@document_comment.user_id = current_user.id
		@document_comment.document_id = @document.id

		if @document_comment.save
		  puts "Comment added!"
		else
		  puts "Error adding comment!"
		  puts @document_comment.errors.full_messages
		end
		return @tbdoc.apiresponse
    end
  end
end
