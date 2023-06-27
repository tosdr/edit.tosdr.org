class Annotation < ApplicationRecord
  include Elasticsearch::Model::Proxy
  # include Elasticsearch::Model::Callbacks
  self.table_name = 'annotation'
  belongs_to :h_document, class_name: 'HDocument', foreign_key: 'document_id'

  def target
    target = {"source": target_uri}
    target["selector"] = target_selectors if target_selectors
    [target]
  end

  def thread_ids
    # we won't be dealing with threads in the migration so just return [] for now
    []
  end

  def document_dict
    return {} unless h_document
    document_dict = {}
    document_dict["title"] = [h_document.title] if h_document.title
    document_dict["web_uri"] = h_document.web_uri if h_document.web_uri
    document_dict
  end

  def split_userid
    regex = /^acct:([^@]+)@(.*)$/
    matches = regex.match(userid)
    return {"username": matches[1], "domain": matches[2]} if matches
  end

  def determine_url_safe_id(value)
    hex_string = UUID.validate(value) && value.split("-").join
    data = Binascii.a2b_hex(hex_string)
    b64_encoded = Base64.urlsafe_encode64(data)
    b64_encoded[0...-2]
  end

  def annotation_dict
    document = document_dict
    userid_parts = split_userid

    result = {
      "authority": userid_parts[:domain],
      "id": determine_url_safe_id(id),
      "created": Time.iso8601(DateTime.parse(created.to_s).to_s),
      "updated": Time.iso8601(DateTime.parse(updated.to_s).to_s),
      "user": userid,
      "user_raw": userid,
      "uri": target_uri,
      "text": text || "",
      "tags": tags,
      "tags_raw": tags,
      "group": groupid,
      "shared": shared,
      "target": target,
      "document": document,
      "thread_ids": thread_ids,
    }

    result
  end

  def index_elasticsearch
    client = Elasticsearch::Client.new url: 'http://elasticsearch:9200', index: 'hypothesis', log: true
    __elasticsearch__.client = client
    __elasticsearch__.client.index index: 'hypothesis', type: 'annotation', id: determine_url_safe_id(id), body: annotation_dict
  end
end