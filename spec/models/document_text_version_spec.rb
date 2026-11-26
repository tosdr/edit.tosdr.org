require 'rails_helper'

describe 'Document#text_version', type: :model do
  def sha256(text)
    Digest::SHA256.hexdigest(text)
  end

  it 'is the SHA-256 of the text when a document is created' do
    document = create(:document, text: 'First version.')

    expect(document.text_version).to eq(sha256('First version.'))
  end

  it 'changes with the text and returns to the earlier value when the text reverts' do
    document = create(:document, text: 'First version.')
    first = document.text_version

    document.update!(text: 'Second version.')
    expect(document.text_version).to eq(sha256('Second version.'))

    document.update!(text: 'First version.')
    expect(document.text_version).to eq(first)
  end

  it 'is left alone when other attributes change' do
    document = create(:document, text: 'First version.')
    document.update_columns(text_version: 'sentinel')

    document.update!(name: 'Renamed policy')

    expect(document.reload.text_version).to eq('sentinel')
  end
end
