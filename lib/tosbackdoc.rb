require 'sanitize'
require 'httparty'
require 'json'

class TOSBackDoc
  @site = nil
  @name ||= nil
  @url ||= nil
  @xpath ||= nil
  @newdata ||= nil
  @reviewed ||= nil
  @save_dir ||= nil
  @save_path ||= nil
  @apiresponse ||= nil
  @server ||= 'eu'

  def initialize(hash)
    @site = hash[:site]
    @name = hash[:name]
    @server = (hash[:server].nil? || hash[:server].empty? || hash[:server] == false || hash[:server] == "false" ) ? "eu" : hash[:server]
    @url = hash[:url]
    @xpath = (hash[:xpath] == "") ? nil : hash[:xpath]
    @reviewed = (hash[:reviewed].nil? || hash[:reviewed].empty? || hash[:reviewed] == false || hash[:reviewed] == "false" ) ? nil : hash[:reviewed]
    @save_dir = (@reviewed == nil) ? "#{$results_path}#{@site}/" : "#{$reviewed_crawl_path}#{@site}/"
    @save_path = "#{@save_dir}#{@name}.txt"
  end #init

  def scrape
    download_and_filter_with_xpath()
    if @newdata
      strip_tags()
      format_newdata()
    end
  end

  def write
    unless crawl_empty?
      Dir.mkdir(@save_dir) unless File.exists?(@save_dir)

      crawl_file = File.open(@save_path,"w") # new file or overwrite old file
      crawl_file.puts @newdata
      crawl_file.close
    else
      TOSBackApp.log_stuff("#{@site}, #{@name} crawl was empty.",$empty_log)
    end
  end #write

  def check_notify
    if @reviewed
      if crawl_empty? && !skip_notify?
        $notifier.blank << {site: @site, name: @name}
      elsif !crawl_empty?
        $notifier.changes << {site: @site, name: @name} if data_changed?
      end
    end
  end

  def crawl_empty?
    @newdata.nil? || @newdata.chomp == ""
  end

  def data_changed?
    prev_file = File.exists?(@save_path) ? File.open(@save_path) : nil
    if prev_file
      prev_data = prev_file.read
      prev_file.close
    end

    if prev_data
      prev_data.chomp != @newdata.chomp
    else
      true
    end
  end

  def skip_notify?
    prev_mtime = File.exists?(@save_path) ? File.mtime(@save_path) : nil
    prev_mtime && prev_mtime > Time.now - 216000
  end

  def puts_doc
    puts @newdata
  end #puts_doc

  def download_and_filter_with_xpath
	begin
		if not @xpath.blank?
			response = HTTParty.get('https://crawler.'+@server+'.tosdr.org/?url='+ CGI.escape(@url) +'&xpath='+ CGI.escape(@xpath) +'&apikey='+ ENV["CRAWLER_API_KEY"])
		else
			response = HTTParty.get('https://crawler.'+@server+'.tosdr.org/?url='+ CGI.escape(@url) +'&apikey='+ ENV["CRAWLER_API_KEY"])
		end
		@apiresponse = JSON.parse(response.body)
		  
		if @apiresponse["error"]
			puts @apiresponse["message"]
		else
			@newdata = @apiresponse["raw_html"]
		end
	rescue => e
		@apiresponse = {"error" => true, "message" => { "name" => "Crawler Request Rescue", "message" => e}}
		puts e
	end
  end

  def format_newdata()
    @newdata.gsub!(/\s{2,}/," ") # changes big gaps of space to a single space
    @newdata.gsub!(/\.\s|;\s/,".\n") # adds new line char after all ". "'s
    @newdata.gsub!(/\n\s/,"\n") # removes single spaces at the beginning of lines
    @newdata.gsub!(/>\s*</,">\n<") # newline between tags
  end #format_tos

  def strip_tags()
    begin
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => []) # strips non-style html tags and removes content between <script> and <style> tags
      puts "stripped"
    rescue Encoding::CompatibilityError
      # puts "rescued"
      @newdata.encode!("UTF-8", :undef => :replace)
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
    rescue ArgumentError
      # puts "Argument error"
      @newdata.encode!('ISO-8859-1', {:invalid => :replace, :undef => :replace})
      @newdata.encode!('UTF-8', {:invalid => :replace, :undef => :replace})
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
    end
  end #strip_tags

  attr_accessor :name, :url, :xpath, :newdata, :site, :has_prev, :reviewed, :apiresponse
  private :download_and_filter_with_xpath, :strip_tags, :format_newdata, :skip_notify?, :data_changed?
end #TOSBackDoc

puts 'TOSBackDoc loaded'
