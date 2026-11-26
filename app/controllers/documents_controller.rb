# frozen_string_literal: true

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  include Pundit::Authorization

  CONTACT_LINK = "<a href='mailto:team@tosdr.org'>team@tosdr.org</a>"

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_document, only: %i[show edit update crawl deprecate]
  before_action :set_services, only: %i[new edit create update]
  before_action :set_document_names, only: %i[new edit create update]

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

    crawl = crawl_text(@document)

    if crawl[:success] && @document.save
      flash[:notice] = 'Document created!'
      redirect_to document_path(@document)
    else
      # Run the validations even when the crawl failed, so field errors (blank or duplicate
      # URL, etc.) show next to the inputs alongside the crawl failure.
      @document.validate unless crawl[:success]
      flash.now[:warning] = crawl[:success] ? 'Document could not be saved.' : crawl[:message]
      render :new
    end
  end

  def update
    authorize @document

    @document.assign_attributes(document_params)

    if document_params[:document_type_id].present?
      document_type = DocumentType.find(document_params[:document_type_id])
      @document.name = document_type.name
    end

    # Recrawl only when the location changed. Nothing is saved until the crawl has succeeded,
    # so a failed crawl can't leave a new URL/selector persisted next to the old location's text.
    location_changed = @document.url_changed? || @document.selector_changed?

    unless @document.valid?
      flash.now[:warning] = 'Document failed to update.'
      return render 'edit'
    end

    if location_changed
      crawl = crawl_text(@document)
      unless crawl[:success]
        flash.now[:warning] = crawl[:message]
        return render 'edit'
      end
    end

    if @document.save
      flash[:notice] = location_changed ? "Document updated and recrawled. #{text_change_summary}".strip : 'Document updated.'
      redirect_to document_path(@document)
    else
      flash.now[:warning] = 'Document failed to update.'
      render 'edit'
    end
  end

  def deprecate
    authorize @document, :deprecate?

    if @document.points.exists? && !current_user.admin?
      flash[:alert] =
        'This document has points attached. Please ask an admin to deprecate it.'
      redirect_to document_path(@document)
    else
      service = @document.service
      @document.deprecate!
      flash[:notice] = 'Document deprecated.'
      redirect_to annotate_path(service)
    end
  end

  def show
    authorize @document

    @points = @document.points.includes(:case, :user)
    @missing_points = @points.where(status: 'approved-not-found')
    @last_crawled_at = @document.formatted_last_crawl_date
    @name = @document.document_type ? @document.document_type.name : @document.name
  end

  def crawl
    authorize @document

    crawl = crawl_text(@document)

    if !crawl[:success]
      flash[:warning] = crawl[:message]
    elsif @document.save
      flash[:notice] = if @document.saved_change_to_text?
                         "Crawl successful. Document text updated. #{text_change_summary}".strip
                       else
                         'Crawl successful. Document text unchanged.'
                       end
    else
      errors = ERB::Util.html_escape(@document.errors.full_messages.to_sentence)
      flash[:warning] = "The crawl succeeded, but the document could not be saved: #{errors}"
    end

    redirect_to document_path(@document)
  end

  private

  def set_document
    @document = Document.find(params[:id].to_i)
    # Defensive: an orphan document whose service was deprecated out-of-band (before the daily
    # backfill re-hides it) has a nil service and would 500 every view that reads it. Treat it
    # as gone until the sweep deprecates it. Covers show/edit/crawl/update/deprecate.
    redirect_to documents_path, alert: 'That document is no longer available.' if @document.service.nil?
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

  # Describes what the text change did to the document's points, from the reconciliation that
  # Document runs after saving new text. Blank when the text didn't change.
  def text_change_summary
    reconciliation = @document.point_reconciliation
    return '' unless reconciliation

    summary = "#{helpers.pluralize(reconciliation.missing.length, 'point')} missing from the new text."
    summary += " #{helpers.pluralize(reconciliation.relocated.length, 'quote')} relocated." if reconciliation.relocated.any?
    if reconciliation.found_again.any?
      summary += " #{helpers.pluralize(reconciliation.found_again.length, 'previously missing point')} " \
                 'found again and restored.'
    end
    summary
  end

  # Fetch the document's text from the OTA crawler. On success, assigns text and
  # last_crawl_date to the (unsaved) document and returns { success: true }. On failure,
  # leaves the document untouched, logs one line, and returns { success: false, message: }.
  # The message is HTML because flashes render raw, so every dynamic part is escaped.
  def crawl_text(document)
    if document.url.blank? || document.selector.blank?
      return crawl_failure(document, 'this document needs both a URL and a CSS selector to be crawled.',
                           contact: false)
    end

    uri = crawler_uri
    return crawl_failure(document, 'the crawler is not configured (OTA_URL is not set).') unless uri

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(build_request(document, uri))
    end

    unless response.is_a?(Net::HTTPSuccess)
      return crawl_failure(document, "double check the URL and selector.")
    end

    # The crawler answers with the extracted document as a JSON string.
    text = JSON.parse(response.body)
    unless text.is_a?(String) && text.present?
      return crawl_failure(document, 'the crawler returned no text for this URL and selector.')
    end

    document.text = text
    document.last_crawl_date = Time.now.utc
    { success: true }
  rescue JSON::ParserError
    crawl_failure(document, 'the crawler returned a response that could not be read.')
  rescue SocketError => e
    crawl_failure(document, "the crawler is unreachable (#{e.message}).")
  rescue Timeout::Error => e
    crawl_failure(document, "the crawler timed out (#{e.message}).")
  rescue StandardError => e
    # Our crawler fork drops the connection instead of answering when it can't load the page
    # or the selector matches nothing, which surfaces here (typically as an EOFError).
    crawl_failure(document, "#{e.class}: #{e.message}. If the crawler is running, check the URL and " \
                            'selector: the crawler drops the connection when it cannot load the page or ' \
                            'the selector matches nothing.')
  end

  def crawl_failure(document, reason, contact: true)
    Rails.logger.warn("Crawl failed for document #{document.id || '(new)'} (#{document.url}): #{reason}")

    message = "Crawl failed: #{ERB::Util.html_escape(reason)}"
    message += " Contact #{CONTACT_LINK} if this keeps happening." if contact
    { success: false, message: message }
  end

  def crawler_uri
    url = ENV['OTA_URL']
    URI(url) if url.present?
  end

  def build_request(document, uri)
    request = Net::HTTP::Post.new(uri)
    request.body = { fetch: document.url, select: document.selector }.to_json
    request.content_type = 'application/json'
    request['Authorization'] = "Bearer #{ENV['OTA_API_SECRET']}"
    request
  end
end
