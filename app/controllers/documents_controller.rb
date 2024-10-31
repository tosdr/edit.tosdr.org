# frozen_string_literal: true

require "#{Rails.root}/lib/tosbackdoc.rb"
require 'zlib'

puts 'loaded?'
puts TOSBackDoc

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_document, only: %i[show edit update crawl restore_points]
  before_action :set_services, only: %i[new edit create update]
  before_action :set_document_names, only: %i[new edit create update]
  before_action :set_uri, only: %i[new edit create update crawl]

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

    document_url = document_params[:url]
    selector = document_params[:selector]

    request = build_request(document_url, @uri, selector)
    results = fetch_text(request, @uri, @document)

    @document = results[:document]
    message = results[:message]

    if @document.save
      flash[:notice] = message
      redirect_to document_path(@document)
    else
      flash.now[:warning] = message.html_safe if message
      render :new
    end
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
    run_crawler = @document.saved_changes.keys.any? { |attribute| %w[url selector].include? attribute }
    #### need to crawl regardless once we deploy
    if run_crawler
      request = build_request(@document.url, @uri, @document.selector)
      results = fetch_text(request, @uri, @document)

      @document = results[:document]
      @document.last_crawl_date = Time.now.getutc
      message = results[:message]
      crawl_sucessful = results[:crawl_sucessful]
    end

    if (crawl_sucessful || !run_crawler) && @document.save
      message ||= 'Document updated'
      flash[:notice] = message
      redirect_to document_path(@document)
    else
      message ||= 'Document failed to update'
      flash.now[:warning] = message
      render 'edit'
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

    @points = @document.points
    @missing_points = @points.where(status: 'approved-not-found')
    @last_crawled_at = @document.formatted_last_crawl_date
    @name = @document.document_type ? @document.document_type.name : @document.name
  end

  def crawl
    authorize @document

    old_text = @document.text
    request = build_request(@document.url, @uri, @document.selector)
    results = fetch_text(request, @uri, @document)

    @document = results[:document]
    @document.last_crawl_date = Time.now.getutc
    message = results[:message]
    crawl_sucessful = results[:crawl_sucessful]

    text_changed = old_text != @document.text

    if crawl_sucessful && text_changed && @document.save
      missing_points = analyze_points
      missing_points_count = missing_points.length.to_s
      message = `Crawl successful. Document text updated. There are #{missing_points_count} points missing from the new text.`
      flash[:notice] = message
    elsif crawl_sucessful && !text_changed && @document.save
      flash[:notice] = 'Crawl successful. Document text unchanged.'
    else
      message ||= 'Crawl failed!'
      flash.now[:warning] = message
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

  def document_params
    params.require(:document).permit(:service, :service_id, :user_id, :document_type_id, :name, :url, :selector)
  end

  def set_uri
    url = ENV['OTA_URL']
    @uri = URI(url)
  end

  def build_request(document_url, uri, selector)
    request = Net::HTTP::Post.new(uri)
    params = '{"fetch": "' + document_url + '","select": "' + selector + '"}'
    request.body = params
    request.content_type = 'application/json'
    token = ENV['OTA_API_SECRET']
    request['Authorization'] = "Bearer #{token}"

    request
  end

  def analyze_points
    document.handle_missing_points
  end

  def fetch_text(request, uri, document)
    crawl_sucessful = false
    begin
      response_text = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      case response_text
      when Net::HTTPSuccess
        puts 'HTTP Success'
        response_body = response_text.body
        parsed_response_body = JSON.parse(response_body)
        document.text = parsed_response_body
        crawl_sucessful = true
        message = 'Document created!'
      else
        Rails.logger.error("HTTP Error: #{response.code} - #{response.message}")
        message = "HTTP Error: Could not retrieve document text. Contact <a href='mailto:team@tosdr.org'>team@tosdr.org</a>. Details: #{response.code} - #{response.message}"
      end
    rescue SocketError => e
      # Handle network-related errors
      Rails.logger.error("Network Error: #{e.message}")
      message = "Network Error: Crawler unreachable. Could not retrieve document text. Contact <a href='mailto:team@tosdr.org'>team@tosdr.org</a>. Details: #{e.message}"
    rescue Timeout::Error => e
      # Handle timeout errors
      Rails.logger.error("Timeout Error: #{e.message}")
      message = "Timeout Error:  Could not retrieve document text. Contact <a href='mailto:team@tosdr.org'>team@tosdr.org</a>. Details: #{e.message}"
    rescue StandardError => e
      # Handle any other standard errors
      Rails.logger.error("Standard Error: #{e.message}")
      message = "Standard Error: Could not retrieve document text. Is the crawler running? Contact <a href='mailto:team@tosdr.org'>team@tosdr.org</a>. Details: #{e.message}"
    end

    { document: document, message: message, crawl_sucessful: crawl_sucessful }
  end
end
