require 'rails_helper'

describe User, type: :model do
  describe 'level refresh' do
    let(:user) { create(:user_confirmed) }

    it 'calculates levels from rising square thresholds' do
      expect(described_class.level_for_approved_points(0)).to eq(1)
      expect(described_class.level_for_approved_points(1)).to eq(2)
      expect(described_class.level_for_approved_points(3)).to eq(2)
      expect(described_class.level_for_approved_points(4)).to eq(3)
      expect(described_class.level_for_approved_points(8)).to eq(3)
      expect(described_class.level_for_approved_points(9)).to eq(4)
    end

    it 'moves a user to level 2 after their first approved point' do
      create(:point, user: user, status: 'approved')

      expect(user.reload.approved_points_count).to eq(1)
      expect(user.level).to eq(2)
    end

    it 'moves a user above level 2 as approved points increase' do
      create_list(:point, 4, user: user, status: 'approved')

      expect(user.reload.approved_points_count).to eq(4)
      expect(user.level).to eq(3)
    end

    it 'moves a user back to level 1 when their last approved point stops being approved' do
      point = create(:point, user: user, status: 'approved')

      point.update!(status: 'changes-requested')

      expect(user.reload.approved_points_count).to eq(0)
      expect(user.level).to eq(1)
    end
  end
end
