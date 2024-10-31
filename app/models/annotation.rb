# frozen_string_literal: true

require 'elasticsearch/model'

class Annotation < ApplicationRecord
  include Elasticsearch::Model::Proxy
  include Elasticsearch::Model::Callbacks
  self.table_name = 'annotation'
  belongs_to :h_document, class_name: 'HDocument', foreign_key: 'document_id'

  def target
    target = { "source": target_uri }
    target['selector'] = target_selectors if target_selectors
    [target]
  end

  def thread_ids
    # we won't be dealing with threads in the migration so just return [] for now
    []
  end

  def document_dict
    return {} unless h_document

    document_dict = {}
    document_dict['title'] = [h_document.title] if h_document.title
    document_dict['web_uri'] = h_document.web_uri if h_document.web_uri
    document_dict
  end

  def split_userid
    regex = /^acct:([^@]+)@(.*)$/
    matches = regex.match(userid)
    return { "username": matches[1], "domain": matches[2] } if matches
  end

  def annotation_dict
    document = document_dict
    userid_parts = split_userid

    {
      "authority": userid_parts[:domain],
      "id": StringConverter.new(string: id).to_url_safe,
      "created": Time.iso8601(DateTime.parse(created.to_s).to_s),
      "updated": Time.iso8601(DateTime.parse(updated.to_s).to_s),
      "user": userid,
      "user_raw": userid,
      "uri": target_uri,
      "text": text || '',
      "tags": tags,
      "tags_raw": tags,
      "group": groupid,
      "shared": shared,
      "target": target,
      "document": document,
      "thread_ids": thread_ids
    }
  end

  def dynamic_update(table_name, id, updates)
    # Step 1: Build the SET clause dynamically
    set_clause = updates.map do |column, value|
      "#{ActiveRecord::Base.connection.quote_column_name(column)} = #{ActiveRecord::Base.connection.quote(value)}"
    end.join(', ')

    # Step 2: Prepare the SQL statement
    sql = "UPDATE #{ActiveRecord::Base.connection.quote_table_name(table_name)} SET #{set_clause} WHERE id = #{ActiveRecord::Base.connection.quote(id)};"

    # Step 3: Execute the SQL statement
    begin
      result = ActiveRecord::Base.connection.exec_query(sql)
      puts "#{result.rows.count} record(s) updated successfully!" if result.rows.count > 0
    rescue ActiveRecord::StatementInvalid => e
      puts "An error occurred: #{e.message}"
    end
  end

  # # Example usage
  # updates = {
  #   target_uri: annotation['target_uri'].gsub('https://edit.tosdr.org', 'http://localhost:9090'),
  #   target_uri_normalized: annotation['target_uri_normalized'].gsub('httpx://edit.tosdr.org', 'httpx://localhost:9090')
  # }

  # dynamic_update('annotation', annotation['id'], updates)

  def restore
    client = Elasticsearch::Client.new url: 'http://elasticsearch:9200', index: 'hypothesis', log: true
    __elasticsearch__.client = client

    begin
      # Attempt to get a document that might not exist
      response = client.get(index: 'hypothesis', type: 'annotation',
                            id: StringConverter.new(string: self['id']).to_url_safe)
      puts response
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      # Handle the 404 "Not Found" error
      puts 'Document not found - adding document'

      updates = {
        target_uri: self['target_uri'].gsub('https://edit.tosdr.org', 'http://localhost:9090'),
        target_uri_normalized: self['target_uri_normalized'].gsub('httpx://edit.tosdr.org',
                                                                  'httpx://localhost:9090')
      }
      dynamic_update('annotation', self['id'], updates)
      self
    rescue StandardError => e
      # Handle other potential errors
      puts "An error occurred: #{e.message}"
      nil
    end
  end

  def index_elasticsearch
    client = Elasticsearch::Client.new url: 'http://elasticsearch:9200', index: 'hypothesis', log: true
    __elasticsearch__.client = client
    __elasticsearch__.client.index index: 'hypothesis', type: 'annotation',
                                   id: StringConverter.new(string: id).to_url_safe, body: annotation_dict
  end
end
