class SnippetCacheRefreshJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find_by(id: document_id)
    return unless document

    Rails.logger.info "[SnippetCache] Rebuilding snippet cache for Document ##{document.id}"
    snippets_data = document.retrieve_snippets(document.text)
    Rails.cache.write("doc:#{document.id}:snippets:v1", snippets_data)
    Rails.logger.info "[SnippetCache] Cache refreshed successfully for Document ##{document.id}"
  end
end