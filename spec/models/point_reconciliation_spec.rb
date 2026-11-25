require 'rails_helper'

# Keeping points in step with their document's text. Whenever the text changes,
# Document#reconcile_points! keeps each tracked quote where it is, relocates it, or flags it as
# not found. The annotate view's snippet builder (Document#snippets) only reads the result.
describe 'Point reconciliation', type: :model do
  let(:text) { 'We collect your data and share it with partners.' }
  let(:document) { create(:document, text: text) }

  # A point whose offsets point at `quote` in `text`. When the quote is absent from `text`, the
  # offsets get a placeholder so the point stays tracked (mirrors real rows).
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

  describe 'Document#reconcile_points!' do
    it 'leaves a quote that is still at its stored location alone' do
      point = quote_point('collect your data', status: 'approved')

      expect { document.reconcile_points! }.not_to(change { point.reload.updated_at })
      expect(document.point_reconciliation.relocated).to be_empty
    end

    it 'relocates a quote that moved, keeping its status' do
      point = quote_point('share it with partners', status: 'approved')
      document.update_columns(text: "New intro. #{text}")

      result = document.reconcile_points!

      point.reload
      expect(point.status).to eq('approved')
      expect(point.quote_start).to eq(document.text.index('share it with partners'))
      expect(point.quote_end).to eq(point.quote_start + 'share it with partners'.length)
      expect(result.relocated).to eq([point])
    end

    it 'relocates a quote whose markup, spacing and case changed, saving the raw text at the new spot' do
      point = quote_point('collect your data', status: 'pending')
      document.update_columns(text: '<p>We <b>Collect</b>  your data now.</p>')

      document.reconcile_points!

      point.reload
      expect(point.status).to eq('pending')
      # The range runs from the first to the last visible character, so the opening <b> is outside it.
      expect(point.quote_text).to eq('Collect</b>  your data')
      expect(document.text[point.quote_start...point.quote_end]).to eq(point.quote_text)
    end

    it 'demotes approved and pending points whose quote is gone' do
      approved = quote_point('we will never sell your data', status: 'approved')
      pending = quote_point('we delete everything', status: 'pending')

      result = document.reconcile_points!

      expect(approved.reload.status).to eq('approved-not-found')
      expect(pending.reload.status).to eq('pending-not-found')
      expect(result.missing).to contain_exactly(approved, pending)
    end

    it 'returns *-not-found points to their status once the quote is back' do
      approved = quote_point('collect your data', status: 'approved-not-found')
      pending = quote_point('share it with partners', status: 'pending-not-found')

      result = document.reconcile_points!

      expect(approved.reload.status).to eq('approved')
      expect(pending.reload.status).to eq('pending')
      expect(result.found_again).to contain_exactly(approved, pending)
    end

    it 'ignores declined points and points without a quote or offsets' do
      declined = quote_point('vanished but declined', status: 'declined')
      no_quote = create(:point, document: document, service: document.service, status: 'approved', quote_text: nil)
      # Created from the Hypothesis sidebar: a quote but no offsets. Not tracked by Phoenix yet.
      hypothesis = create(:point, document: document, service: document.service, status: 'approved',
                                  quote_text: 'vanished from the text', annotation_ref: 'abc123')

      expect { document.reconcile_points! }.not_to raise_error
      expect(declined.reload.status).to eq('declined')
      expect(no_quote.reload.status).to eq('approved')
      expect(hypothesis.reload.status).to eq('approved')
    end

    it 'is idempotent' do
      gone = quote_point('we will never sell your data', status: 'approved')
      moved = quote_point('share it with partners', status: 'approved')
      document.update_columns(text: "New intro. #{text}")

      document.reconcile_points!
      second = document.reconcile_points!

      expect(gone.reload.status).to eq('approved-not-found')
      expect(second.relocated).to be_empty
      expect(second.found_again).to be_empty
      expect { document.reconcile_points! }.not_to(change { moved.reload.updated_at })
    end
  end

  describe 'saving new text' do
    it 'reconciles the points when the text changes' do
      kept = quote_point('collect your data', status: 'approved')
      dropped = quote_point('share it with partners', status: 'approved')

      document.update!(text: 'Update: we collect your data and keep it.')

      expect(kept.reload.status).to eq('approved')
      expect(kept.quote_start).to eq(document.text.index('collect your data'))
      expect(dropped.reload.status).to eq('approved-not-found')
      expect(document.point_reconciliation.missing).to contain_exactly(dropped)
      expect(document.point_reconciliation.relocated).to contain_exactly(kept)
    end

    it 'does not reconcile when the text is unchanged' do
      gone = quote_point('we will never sell your data', status: 'approved')
      fresh = Document.find(document.id)

      fresh.update!(name: 'Renamed policy')

      expect(fresh.point_reconciliation).to be_nil
      expect(gone.reload.status).to eq('approved')
    end
  end

  describe 'Point#mark_quote_not_found! / #mark_quote_found!' do
    it 'maps approved <-> approved-not-found and pending <-> pending-not-found' do
      approved = create(:point, status: 'approved')
      pending = create(:point, status: 'pending')

      approved.mark_quote_not_found!
      pending.mark_quote_not_found!
      expect(approved.reload.status).to eq('approved-not-found')
      expect(pending.reload.status).to eq('pending-not-found')

      approved.mark_quote_found!(0...4, 'some')
      pending.mark_quote_found!(0...4, 'some')
      expect(approved.reload.status).to eq('approved')
      expect(pending.reload.status).to eq('pending')
      expect([pending.quote_start, pending.quote_end, pending.quote_text]).to eq([0, 4, 'some'])
    end

    it 'leaves any other status alone' do
      draft = create(:point, status: 'draft')

      expect(draft.mark_quote_not_found!).to be(false)
      draft.mark_quote_found!(0...4, 'some')
      expect(draft.reload.status).to eq('draft')
    end
  end

  describe 'Document#snippets (annotate view)' do
    it 'is read-only: it does not change point statuses or offsets' do
      gone = quote_point('we will never sell your data', status: 'approved')

      expect { document.snippets }.not_to(change { gone.reload.attributes })
    end

    it 'highlights quotes at their stored offsets and skips stale ones' do
      present = quote_point('collect your data', status: 'approved')
      stale = quote_point('share it with partners', status: 'approved')
      stale.update_columns(quote_start: 1, quote_end: 2)

      ids = document.snippets.filter_map { |snippet| snippet[:pointId] }

      expect(ids).to eq([present.id])
    end

    it 'highlights a quote at the very start of the text and one immediately after it' do
      first = quote_point('We collect', status: 'approved')
      second = quote_point(' your data', status: 'approved')

      snippets = document.snippets

      expect(snippets.filter_map { |snippet| snippet[:pointId] }).to eq([first.id, second.id])
      expect(snippets.map { |snippet| snippet[:text] }.join).to eq(text)
    end

    it 'does not crash on a legacy point that has only an end offset' do
      legacy = quote_point('collect your data', status: 'approved')
      legacy.update_columns(quote_start: nil)

      expect { document.snippets }.not_to raise_error
      expect(document.snippets.filter_map { |snippet| snippet[:pointId] }).to be_empty
    end
  end
end
