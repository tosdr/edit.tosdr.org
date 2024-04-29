namespace :spam do
  desc 'Clean out objects marked as spam by curators'
  task clean_spam: :environment do
    if Spam.where(cleaned: false, flagged_by_admin_or_curator: true).any?
      object_types = Spam.where(cleaned: false, flagged_by_admin_or_curator: true).pluck(:spammable_type).uniq
      object_types.each do |type|
        ids = Spam.where(spammable_type: type).pluck(:spammable_id)
        type.constantize.where(id: ids).delete_all
        Spam.where(spammable_id: ids).update_all(cleaned: true)
      end
    end
  end

  desc 'Delete comment objects with external URIs'

  def extract_uris(value)
    URI.extract(value)
  end

  def find_spam(items)
    items.select do |item|
      summary = item.summary
      uris = extract_uris(summary)
      uris.length.positive?
    end

    items
  end

  task clean_comments: :environment do
    case_comments = find_spam(CaseComment.all)
    case_comments.delete_all if case_comments.length.positive?

    document_comments = find_spam(DocumentComment.all)
    document_comments.delete_all if document_comments.length.positive?

    point_comments = find_spam(PointComment.all)
    point_comments.delete_all if point_comments.length.positive?

    topic_comments = find_spam(TopicComment.all)
    topic_comments.delete_all if topic_comments.length.positive?
  end
end
