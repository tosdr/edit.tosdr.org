namespace :spam do
  desc "Clean out objects marked as spam by curators"
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
end
