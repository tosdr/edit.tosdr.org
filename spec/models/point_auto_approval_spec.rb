require 'rails_helper'

describe Point, type: :model do
  describe 'verified contributor auto approval' do
    let(:verified_user) { create(:user_confirmed, verified_contributor: true) }
    let(:regular_user) { create(:user_confirmed, email: 'regular@test.org', username: 'regular') }

    it 'sets a veto period deadline for pending points by verified contributors' do
      point = create(:point, user: verified_user, status: 'pending')

      expect(point.auto_approve_after).to be_within(1.minute).of(7.days.from_now)
    end

    it 'does not set a deadline for regular contributors' do
      point = create(:point, user: regular_user, status: 'pending')

      expect(point.auto_approve_after).to be_nil
    end

    it 'clears the deadline when the countdown is stopped by a review status' do
      point = create(:point, user: verified_user, status: 'pending')

      point.update!(status: 'changes-requested')

      expect(point.auto_approve_after).to be_nil
    end

    it 'approves verified contributor points after the veto period expires' do
      point = create(:point, user: verified_user, status: 'pending', auto_approve_after: 1.hour.ago)

      described_class.auto_approve_veto_expired

      expect(point.reload.status).to eq('approved')
      expect(point.auto_approve_after).to be_nil
      expect(point.point_comments.last.summary).to include('automatically approved')
    end

    it 'does not approve verified contributor points before the veto period expires' do
      point = create(:point, user: verified_user, status: 'pending', auto_approve_after: 1.hour.from_now)

      described_class.auto_approve_veto_expired

      expect(point.reload.status).to eq('pending')
    end

    it 'requests changes after 3 level 2 contributor vetoes' do
      point = create(:point, user: verified_user, status: 'pending')
      voters = create_list(:user_confirmed, 3) do |user, index|
        user.update!(email: "voter#{index}@test.org", username: "voter#{index}")
        create(:point, user: user, status: 'approved')
      end

      voters.each { |voter| point.veto_period_veto!(voter.reload) }

      expect(point.reload.status).to eq('changes-requested')
      expect(point.auto_approve_after).to be_nil
      expect(point.point_vetoes.count).to eq(3)
      expect(point.point_comments.last.summary).to include('3 level 2 contributor veto votes')
    end

    it 'does not count vetoes from users below level 2' do
      point = create(:point, user: verified_user, status: 'pending')
      voter = create(:user_confirmed, email: 'new@test.org', username: 'newbie')

      result = point.veto_period_veto!(voter)

      expect(result).to eq(:ineligible)
      expect(point.reload.status).to eq('pending')
      expect(point.point_vetoes.count).to eq(0)
    end
  end
end
