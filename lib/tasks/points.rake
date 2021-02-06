namespace :points do
  desc "Decline points with changes requested"
  task decline: :environment do
	include FontAwesome::Rails::IconHelper
	include ApplicationHelper
	include ActionView::Helpers::TagHelper
    points = Point.all
	matches = points.where("updated_at < ? and status = 'changes-requested'", 2.months.ago )

	puts points.length
	puts matches.length

    matches.each do |point|
		point.status = "declined"
        if point.save

			puts "Point ID: "+ point.id.to_s
			@point_comment = PointComment.new()
			@point_comment.summary = status_badge('declined') + raw('<br>') + 'Point automatically declined as no activity have been monitored over a course of 2 months'
			@point_comment.user_id = "21311"
			@point_comment.point_id = point.id
			if @point_comment.save
			  puts "Comment added!"
			else
				puts "Error adding comment!"
				puts @point_comment.errors.full_messages
			end
		else
			puts "Error declining point!"
			puts point.errors.full_messages
		end
    end
  end
end