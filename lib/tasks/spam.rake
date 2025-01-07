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

  task clean_comments: :environment do
    models = [CaseComment, DocumentComment, PointComment, TopicComment, ServiceComment]
    deleted_count = 0

    models.each do |model|
      puts "Processing #{model.name}..."
      model.find_each do |record|
        user = record.user # Adjust if the association is named differently
        if record.summary.present? && SpamHelpers.contains_external_uri?(user, record.summary)
          puts "Deleting #{model.name} with ID #{record.id} due to external URI in summary."
          record.destroy
          deleted_count += 1
        end
      end
    end

    puts "Cleanup completed. Total records deleted: #{deleted_count}."
  end
end
