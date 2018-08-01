require "#{Rails.root}/lib/tosbackdoc.rb"

puts 'loaded?'
puts TOSBackDoc

class DocumentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_document, only: [:show, :edit, :update]

  def index
    if @query = params[:query]
      @documents = Document.includes(:service).search_by_document_name(@query)
    else
      @documents = Document.includes(:service).all
    end
  end

  def new
    @document = Document.new
    if service = params[:service]
      @document.service = Service.find(service)
    end
  end

  def create
    @document = Document.new(document_params)
    crawl

    if @document.save
      redirect_to @document
    else
      render 'new'
    end
  end

  def update
    @document.update(document_params)
    crawl

    if @document.save
      redirect_to @document
    else
      render 'edit'
    end
  end

  def show
    puts 'crawl?'
    puts params[:crawl]
    crawl if (params[:crawl])
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:service, :service_id, :name, :url, :xpath)
  end

  def crawl
    @tbdoc = TOSBackDoc.new({
      url: @document.url,
      xpath: @document.xpath
    })
    @tbdoc.scrape
    @document.update({ text: @tbdoc.newdata })

    # If text has moved without changing, find it new location.
    # If text _has_ changed and thus can no longer be found, mark it as draft.
    @document.points.each do |point|
      newQuoteStart = @tbdoc.newdata.index(point[:quoteText])
      if (newQuoteStart.nil?)
        puts "Could not find quote"
        puts point[:quoteText]
        point[:status] = 'draft'
        point.save
      else
        if newQuoteStart != point[:quoteStart]
          puts "Text has moved!"
          puts point[:quoteText]
          puts point[:quoteStart]
          puts newQuoteStart
          point[:quoteStart] = newQuoteStart
          point[:quoteEnd] = newQuoteStart + point[:quoteText].length
          point.save
        end
      end
    end
  end
end
