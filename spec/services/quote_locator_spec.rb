require 'rails_helper'

RSpec.describe QuoteLocator do
  # The raw text a located range covers -- what would be saved as the point's quote_text.
  def raw_at(text, quote, **options)
    range = described_class.new(text).locate(quote, **options)
    range && text[range]
  end

  describe 'exact matching' do
    let(:text) { 'we share data. Later: we share data with partners.' }

    it 'keeps the stored location while the quote is still there, even if it also occurs earlier' do
      stored = text.rindex('we share data')

      range = described_class.new(text).locate('we share data', stored_start: stored)

      expect(range).to eq(stored...(stored + 'we share data'.length))
    end

    it 'finds a quote that moved' do
      range = described_class.new(text).locate('with partners', stored_start: 0)

      expect(range).to eq(text.index('with partners')...(text.index('with partners') + 'with partners'.length))
    end

    it 'searches the text when there is no stored location' do
      expect(raw_at(text, 'Later:')).to eq('Later:')
    end

    it 'returns nil for a quote that was reworded or removed' do
      expect(described_class.new(text).locate('we sell data')).to be_nil
    end

    it 'returns nil for a blank quote' do
      expect(described_class.new(text).locate('')).to be_nil
      expect(described_class.new(text).locate(nil)).to be_nil
    end
  end

  describe 'matching that ignores tags, whitespace and case' do
    it 'finds a quote whose HTML tags changed, returning the raw text with the new tags' do
      text = '<p>We <strong>collect</strong> your data.</p>'

      expect(raw_at(text, 'We collect your data')).to eq('We <strong>collect</strong> your data')
    end

    it 'finds a quote whose tags were removed' do
      text = '<p>We collect your data.</p>'

      expect(raw_at(text, 'We <em>collect</em> your data')).to eq('We collect your data')
    end

    it 'finds a quote whose whitespace changed, including non-breaking spaces' do
      text = "We collect\n  your&nbsp;data daily."

      expect(raw_at(text, 'We collect your data daily')).to eq("We collect\n  your&nbsp;data daily")
    end

    it 'finds a quote whose capitalization changed' do
      text = 'WE COLLECT YOUR DATA.'

      expect(raw_at(text, 'We collect your data')).to eq('WE COLLECT YOUR DATA')
    end

    it 'leaves out a tag that used to close the quote' do
      text = '<li>Keep your data</li>'

      expect(raw_at(text, 'keep your data</li>')).to eq('Keep your data')
    end

    it 'returns character offsets into the raw text, not into the normalized copy' do
      text = '<h1>Café</h1> <p>Données <b>PERSONNELLES</b> protégées</p>'

      range = described_class.new(text).locate('données personnelles')

      expect(range).to eq(text.index('Données')...(text.index('PERSONNELLES') + 'PERSONNELLES'.length))
      expect(text[range]).to eq('Données <b>PERSONNELLES')
    end

    it 'still requires every visible character to match' do
      expect(described_class.new('We collect your data.').locate('We collected your data')).to be_nil
    end
  end
end
