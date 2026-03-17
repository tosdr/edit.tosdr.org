# frozen_string_literal: true

require 'elasticsearch/model'

elasticsearch_url = ENV['ELASTICSEARCH_URL'].presence

if elasticsearch_url.blank?
  default_host = ENV['ELASTICSEARCH_HOST'].presence || (File.exist?('/.dockerenv') ? 'elasticsearch' : 'localhost')
  elasticsearch_url = "http://#{default_host}:9200"
end

Rails.application.config.x.elasticsearch_url = elasticsearch_url
Elasticsearch::Model.client = Elasticsearch::Client.new(url: elasticsearch_url, log: Rails.env.development?)