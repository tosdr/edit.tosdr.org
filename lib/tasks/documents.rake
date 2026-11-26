# frozen_string_literal: true

namespace :documents do
  # Points are reconciled against a document's text whenever that text changes
  # (Document#reconcile_points!). This one-off pass, run once after deploying that, catches up
  # points whose text changed before: years of stale offsets and unflagged missing quotes.
  # Idempotent, so it is safe to re-run.
  desc 'Relocate every tracked point quote in its document text, flagging quotes that are gone'
  task reconcile_points: :environment do
    documents = 0
    missing = 0
    relocated = 0
    found_again = 0

    Document.where(id: Point.select(:document_id)).find_each do |document|
      result = document.reconcile_points!
      documents += 1
      missing += result.missing.length
      relocated += result.relocated.length
      found_again += result.found_again.length
    end

    puts "Reconciled #{documents} document(s): #{missing} point(s) missing from their text, " \
         "#{relocated} quote(s) relocated, #{found_again} previously missing point(s) found again and restored."
  end
end
