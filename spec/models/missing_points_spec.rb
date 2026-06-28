require 'rails_helper'

# Regression coverage for missing-quote detection. The crawl (write) path
# (Document#handle_missing_points) and the annotation (read) path
# (Document#retrieve_snippets) share a single implementation so they can't drift
# apart again -- a divergence that previously left the write path silently broken.
describe 'Missing-quote detection', type: :model do
  let(:text) { 'We collect your data and share it with partners.' }
  let(:document) { create(:document, text: text) }

  # Build a point carrying a quote. When the quote is absent from `text`, its offset
  # still gets a placeholder so the point remains quote-locatable (mirrors real rows).
  def quote_point(quote, status:)
    start = text.index(quote)
    create(:point,
           document: document,
           service: document.service,
           status: status,
           quote_text: quote,
           quote_start: start || 0,
           quote_end: start ? start + quote.length : quote.length)
  end

  describe 'Document#handle_missing_points' do
    it 'leaves points whose quote is still present untouched (no blanket demotion)' do
      present = quote_point('collect your data', status: 'approved')

      document.handle_missing_points

      expect(present.reload.status).to eq('approved')
    end

    it 'demotes an approved point whose quote vanished to approved-not-found' do
      gone = quote_point('we will never sell your data', status: 'approved')

      document.handle_missing_points

      expect(gone.reload.status).to eq('approved-not-found')
    end

    it 'demotes a pending point whose quote vanished to pending-not-found' do
      gone = quote_point('we will never sell your data', status: 'pending')

      document.handle_missing_points

      expect(gone.reload.status).to eq('pending-not-found')
    end

    it 'returns every missing point, not just the last one' do
      gone1 = quote_point('first vanished quote', status: 'approved')
      gone2 = quote_point('second vanished quote', status: 'pending')
      quote_point('collect your data', status: 'approved') # still present

      missing = document.handle_missing_points

      expect(missing).to contain_exactly(gone1, gone2)
    end

    it 'ignores declined points and points without a locatable quote' do
      declined = quote_point('vanished but declined', status: 'declined')
      no_quote = create(:point, document: document, service: document.service,
                                status: 'approved', quote_text: nil)

      expect { document.handle_missing_points }.not_to raise_error
      expect(declined.reload.status).to eq('declined')
      expect(no_quote.reload.status).to eq('approved')
    end

    it 'is idempotent across repeated runs' do
      gone = quote_point('we will never sell your data', status: 'approved')

      document.handle_missing_points
      expect { document.handle_missing_points }.not_to change { gone.reload.status }
      expect(gone.reload.status).to eq('approved-not-found')
    end
  end

  describe 'Point#mark_quote_not_found!' do
    it 'maps approved -> approved-not-found and pending -> pending-not-found' do
      approved = create(:point, status: 'approved')
      pending = create(:point, status: 'pending')

      approved.mark_quote_not_found!
      pending.mark_quote_not_found!

      expect(approved.reload.status).to eq('approved-not-found')
      expect(pending.reload.status).to eq('pending-not-found')
    end

    it 'is a no-op (returns false) for any other status' do
      draft = create(:point, status: 'draft')

      expect(draft.mark_quote_not_found!).to be(false)
      expect(draft.reload.status).to eq('draft')
    end
  end

  describe 'the read path shares the same detection (Document#snippets)' do
    it 'flags missing points and still returns present ones as snippets' do
      gone = quote_point('we will never sell your data', status: 'approved')
      present = quote_point('collect your data', status: 'approved')

      result = document.snippets

      expect(gone.reload.status).to eq('approved-not-found')
      expect(present.reload.status).to eq('approved')

      snippet_point_ids = result[:snippets].filter_map { |snippet| snippet[:pointId] }
      expect(snippet_point_ids).to include(present.id)
    end
  end
end
