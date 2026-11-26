require 'rails_helper'

describe 'Service rating', type: :model do
  let(:service) { create(:service) }
  let(:document) { create(:document, service: service) }
  let(:bad_case) { create(:case, classification: 'bad') }
  let(:good_case) { create(:case, classification: 'good') }

  def approve(kase, doc: document)
    create(:point, service: service, document: doc, case: kase, status: 'approved')
  end

  it 'counts a case once when it has several approved points in the same document' do
    2.times { approve(bad_case) }
    approve(good_case)

    expect(service.determine_counts).to eq('bad' => 1, 'good' => 1)
    # Counting both bad points would make bad > good and grade it D.
    expect(service.calculate_service_rating).to eq('C')
  end

  it 'counts a case once when its approved points are in different documents' do
    other_document = create(:document, service: service)
    approve(bad_case)
    approve(bad_case, doc: other_document)
    approve(good_case)

    expect(service.determine_counts).to eq('bad' => 1, 'good' => 1)
    expect(service.calculate_service_rating).to eq('C')
  end

  it 'still counts distinct cases with the same classification separately' do
    approve(bad_case)
    approve(create(:case, classification: 'bad'))
    approve(good_case)

    expect(service.determine_counts).to eq('bad' => 2, 'good' => 1)
    expect(service.calculate_service_rating).to eq('D')
  end
end
