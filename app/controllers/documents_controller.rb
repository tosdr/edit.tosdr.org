# frozen_string_literal: true

require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

puts 'loaded?'
puts TOSBackDoc

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  include Pundit::Authorization

  PROD_CRAWLERS = {
    "https://api.tosdr.org/crawl/v1": 'Random',
    "https://api.tosdr.org/crawl/v1/eu": 'Europe (Recommended)',
    "https://api.tosdr.org/crawl/v1/us": 'United States (Recommended)',
    "https://api.tosdr.org/crawl/v1/eu-central": 'Europe (Central)',
    "https://api.tosdr.org/crawl/v1/eu-west": 'Europe (West)',
    "https://api.tosdr.org/crawl/v1/us-east": 'United States (East)',
    "https://api.tosdr.org/crawl/v1/us-west": 'United States (West)'
  }.freeze

  DEV_CRAWLERS = {
    "http://localhost:5000": 'Standalone (localhost:5000)',
    "http://crawler:5000": 'Docker-Compose (crawler:5000)'
  }.freeze

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_document, only: %i[show edit update crawl restore_points]
  before_action :set_services, only: %i[new edit create update]
  before_action :set_document_names, only: %i[new edit create update]
  before_action :set_crawlers, only: %i[new edit create update]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Document
    @q = Document.includes(:service, :document_type).ransack(params[:q])
    @documents = @q.result(distinct: true).page(params[:page] || 1)
  end

  def new
    authorize Document

    @document = Document.new
    service = params[:service_id]

    @document.service = Service.find(service) if service
  end

  def create
    authorize Document

    @document = Document.new(document_params)
    @document.user = current_user
    @document.name = @document.document_type.name if @document.document_type

    # <ActionController::Parameters {"service_id"=>"4", "document_type_id"=>"2", "url"=>"https://opentermsarchive.org/en/privacy-policy", "selector"=>".TextContent_textContent__ToW2S", "crawler_server"=>"http://localhost:5000"} permitted: true>

    # {
    #   "name": "Open Terms Archive",
    #   "documents": {
    #     "Privacy Policy": {
    #       "fetch": "https://opentermsarchive.org/en/privacy-policy",
    #       "select": ".TextContent_textContent__ToW2S"
    #     }
    #   }
    # }
    service = Service.find(document_params[:service_id]).name
    normalized_name = service.strip
    document_type = DocumentType.find(document_params[:document_type_id]).name
    

    # declaration = {}
    # declaration["name"] = normalized_name
    # declaration["documents"] = {}
    # declaration["documents"][document_type] = {}
    # declaration["documents"][document_type]["fetch"] = document_params[:url]
    # declaration["documents"][document_type]["selector"] = document_params[:selector]
    # declaration = JSON.parse(JSON[declaration])

    base_url = "http://localhost:3000/"
    # url = 'https://docs.github.com/en/free-pro-team@latest/github/site-policy/github-privacy-statement'
    url = document_params[:url]
    # selector = '#article-contents'
    selector = document_params[:selector]
    params = '{"fetch": "' + url + '","select": "' + selector + '"}'

    # byebug
    response = HTTParty.post(url, body: params)

    puts '!!!!!!!!!!!!!!!!!!!!!!!!'
    puts response.body

    parsed_response_body = JSON.parse(response.body)


    puts parsed_response_body

    # @document.text = 



    # Net::HTTP implementation
    #    puts "download and filter"
    #    uri = URI("http://localhost:3000")
    #    req = Net::HTTP::Post.new(uri) # => #<Net::HTTP::Post POST>
    #    req.body = '{"fetch": "' + @url + '","select": "' + @xpath + '"}'
    #    req.content_type = 'application/json'
    #    res = Net::HTTP.start(hostname) do |http|
    #      http.request(req)
    #    end
    #    puts res.code
    #    puts res.content_type
    #    puts res.body

    # if @document.save
    #   crawl_result = perform_crawl

    #   unless crawl_result.nil?
    #     if crawl_result['error']
    #       flash[:alert] = crawler_error_message(crawl_result)
    #     else
    #       flash[:notice] = 'The crawler has updated the document'
    #     end
    #   end
      # redirect_to document_path(@document)
    # else
    #   render :new
    # end
  end

  def update
    authorize @document

    @document.update(document_params)

    if document_params[:document_type_id]
      id = document_params[:document_type_id]
      document_type = DocumentType.find(id)
      @document.name = document_type.name unless @document.name == document_type.name
    end

    # we should probably only be running the crawler if the URL or css selector have changed
    run_crawler = @document.saved_changes.keys.any? { |attribute| %w[url selector crawler_server].include? attribute }
    crawl_result = perform_crawl if run_crawler

    if @document.save
      # only want to do this if css selector or URL have changed
      ## text is returned blank when there's a defunct URL or css selector
      ### avoids server error upon 404 error in the crawler
      # need to alert people if the crawler wasn't able to retrieve any text...
      unless crawl_result.nil?
        if crawl_result['error']
          flash[:alert] = crawler_error_message(crawl_result)
        else
          flash[:notice] = 'The crawler has updated the document'
        end
      end
      redirect_to document_path(@document)
    else
      render 'edit', locals: { crawlers: PROD_CRAWLERS }
    end
  end

  def destroy
    @document = Document.find(params[:id] || params[:document_id])
    authorize @document

    service = @document.service
    if @document.points.any?
      flash[:alert] =
        'Users have highlighted points in this document. Update or delete those points before deleting this document.'
      redirect_to document_path(@document)
    else
      @document.destroy
      redirect_to annotate_path(service)
    end
  end

  def show
    authorize @document

    @name = @document.document_type ? @document.document_type.name : @document.name
  end

  def crawl
    authorize @document
    crawl_result = perform_crawl
    if crawl_result['error']
      flash[:alert] = crawler_error_message(crawl_result)
    else
      flash[:notice] = 'The crawler has updated the document'
    end
    redirect_to document_path(@document)
  end

  def restore_points
    authorize @document

    points_to_restore = @document.snippets[:points_needing_restoration]
    restored = []
    not_restored = []

    points_to_restore.each do |point|
      point.restore ? restored << point.id : not_restored << point.id
    end

    message = "Restored #{restored.length} points."
    message += " Unable to restore #{not_restored.length} points." if not_restored.any?
    flash[:alert] = message

    redirect_to annotate_path(@document.service)
  end

  private

  def set_document
    @document = Document.find(params[:id].to_i)
  end

  def set_services
    @services = Service.order('name ASC')
  end

  def set_document_names
    @document_names = DocumentType.where(status: 'approved').order('name ASC')
  end

  def set_crawlers
    @crawlers = Rails.env.development? ? DEV_CRAWLERS : PROD_CRAWLERS
  end

  def document_params
    params.require(:document).permit(:service, :service_id, :user_id, :document_type_id, :name, :url, :selector, :crawler_server)
  end

  def crawler_error_message(result)
    message = result['message']['name'].to_s
    region = result['message']['crawler'].to_s
    stacktrace = CGI::escapeHTML(result['message']['remoteStacktrace'].to_s)

    `It seems that our crawler wasn't able to retrieve any text. <br><br>Reason: #{message} <br>Region: #{region} <br>Stacktrace: #{stacktrace}`
  end

  # to-do: refactor out comment assembly
  def perform_crawl
    authorize @document
    @tbdoc = TOSBackDoc.new({
                              url: @document.url,
                              xpath: @document.selector,
                              server: @document.crawler_server
                            })

    @tbdoc.scrape
    @document_comment = DocumentComment.new

    error = @tbdoc.apiresponse['error']
    if error
      message_name = @tbdoc.apiresponse['message']['name'] || ''
      crawler = @tbdoc.apiresponse['message']['crawler'] || ''
      stacktrace = @tbdoc.apiresponse['message']['remoteStacktrace'] || ''
      @document_comment.summary = '<span class="label label-danger">Attempted to Crawl Document</span><br>Error Message: <kbd>' + message_name + '</kbd><br>Crawler: <kbd>' + crawler + '</kbd><br>Stacktrace: <kbd>' + stacktrace + '</kbd>'
      @document_comment.user_id = current_user.id
      @document_comment.document_id = @document.id
    end

    document_blank = !@document.text.blank?
    old_length = document_blank ? @document.text.length : 0
    old_crc = document_blank ? Zlib.crc32(@document.text) : 0
    new_crc = Zlib.crc32(@tbdoc.newdata)
    changes_made = old_crc != new_crc

    if changes_made
      @document.update(text: @tbdoc.newdata)
      new_length = @document.text ? @document.text.length : 'no text retrieved by crawler'

      # There is a cron job in the crontab of the 'tosdr' user on the forum.tosdr.org
      # server which runs once a day and before it deploys the site from edit.tosdr.org
      # to tosdr.org, it will run the check_quotes script from
      # https://github.com/tosdr/tosback-crawler/blob/225a74b/src/eto-admin.js#L121-L123
      # So that if text has moved without changing, points are updated to the corrected
      # quote_start, quote_end, and quote_text values where possible, and/or their status is
      # switched between:
      # pending <-> pending-not-found
      # approved <-> approved-not-found
      crawler = @tbdoc.apiresponse['message']['crawler'] || ''
      @document_comment.summary = '<span class="label label-info">Document has been crawled</span><br><b>Old length:</b> <kbd>' + old_length.to_s + ' CRC ' + old_crc.to_s + '</kbd><br><b>New length:</b> <kbd>' + new_length.to_s + ' CRC ' + new_crc.to_s + '</kbd><br> Crawler: <kbd>' + crawler + '</kbd>'
      @document_comment.user_id = current_user.id
      @document_comment.document_id = @document.id
    end

    unless changes_made
      @tbdoc.apiresponse['error'] = true
      @tbdoc.apiresponse['message'] = {
        'name' => 'The source document has not been updated. No changes made.',
        'remoteStacktrace' => 'SourceDocument'
      }
    end

    message_name = @tbdoc.apiresponse['message']['name'] || ''
    crawler = @tbdoc.apiresponse['message']['crawler'] || ''
    stacktrace = @tbdoc.apiresponse['message']['remoteStacktrace'] || ''

    @document_comment.summary = '<span class="label label-danger">Attempted to Crawl Document</span><br>Error Message: <kbd>' + message_name + '</kbd><br>Crawler: <kbd>' + crawler + '</kbd><br>Stacktrace: <kbd>' + stacktrace + '</kbd>'
    @document_comment.user_id = current_user.id
    @document_comment.document_id = @document.id

    if @document_comment.save
      puts 'Comment added!'
    else
      puts 'Error adding comment!'
      puts @document_comment.errors.full_messages
    end

    @tbdoc.apiresponse
  end
end
