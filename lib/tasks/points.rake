# frozen_string_literal: true

namespace :points do
  desc 'Generate selection from dump'
  task generate_selection: :environment do
    points = Point.where.not(annotation_ref: nil).where.not(document_id: nil).where.not(status: 'declined').limit(100)
    services = points.pluck(:service_id).uniq
    documents = points.pluck(:document_id).uniq

    # Reason.where.not(point_id: points).delete_all
    PointComment.where.not(point_id: points).delete_all
    Point.where.not(id: points).delete_all
    DocumentComment.where.not(document_id: documents).delete_all
    Document.where.not(id: documents).delete_all
    ServiceComment.where.not(service_id: services).delete_all
    Service.where.not(id: services).delete_all
  end

  task restore_elasticsearch: :environment do
    points = Point.all
    points.each do |point|
      point.restore_elasticsearch
    end
  end

  desc 'Migrate points to hypothesis annotations, index into elasticsearch'
  task migrate: :environment do
    docs_nil_text = Document.where(text: nil)
    points = Point.where.not(document_id: docs_nil_text)
    points = points.where(annotation_ref: nil).where.not(document_id: nil).where.not(status: 'declined')
    points.each do |point|
      point.migrate
    end
  end

  desc 'Decline points with changes requested'
  task decline_changesrequested: :environment do
    include FontAwesome5::Rails::IconHelper
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    points = Point.all
    matches = points.where("updated_at < ? and status = 'changes-requested'", 2.months.ago)

    puts points.length
    puts matches.length

    matches.each do |point|
      point.status = 'declined'
      if point.save

        puts 'Point ID: ' + point.id.to_s
        @point_comment = PointComment.new
        @point_comment.summary = status_badge('declined') + raw('<br>') + 'Point automatically declined as no activity have been monitored over a course of 2 months. Was: changes-requested'
        @point_comment.user_id = '21311'
        @point_comment.point_id = point.id
        if @point_comment.save
          puts 'Comment added!'
        else
          puts 'Error adding comment!'
          puts @point_comment.errors.full_messages
        end
      else
        puts 'Error declining point!'
        puts point.errors.full_messages
      end
    end
  end

  desc 'Decline points with drafts over 2 months old'
  task decline_draft: :environment do
    include FontAwesome5::Rails::IconHelper
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    points = Point.all
    matches = points.where("updated_at < ? and status = 'draft'", 2.months.ago)

    puts points.length
    puts matches.length

    matches.each do |point|
      point.status = 'declined'
      if point.save

        puts 'Point ID: ' + point.id.to_s
        @point_comment = PointComment.new
        @point_comment.summary = status_badge('declined') + raw('<br>') + 'Point automatically declined as no activity have been monitored over a course of 2 months. Was: draft'
        @point_comment.user_id = '21311'
        @point_comment.point_id = point.id
        if @point_comment.save
          puts 'Comment added!'
        else
          puts 'Error adding comment!'
          puts @point_comment.errors.full_messages
        end
      else
        puts 'Error declining point!'
        puts point.errors.full_messages
      end
    end
  end

  desc 'Decline points with *-not-found over 1 month old'
  task decline_notfound: :environment do
    include FontAwesome5::Rails::IconHelper
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    points = Point.all
    matches = points.where("updated_at < ? and (status = 'pending-not-found' or status = 'approved-not-found')",
                           1.months.ago)

    puts points.length
    puts matches.length

    matches.each do |point|
      point.status = 'declined'
      if point.save

        puts 'Point ID: ' + point.id.to_s
        @point_comment = PointComment.new
        @point_comment.summary = status_badge('declined') + raw('<br>') + 'Point automatically declined as no activity have been monitored over a course of 2 months. Was: ' + point.status
        @point_comment.user_id = '21311'
        @point_comment.point_id = point.id
        if @point_comment.save
          puts 'Comment added!'
        else
          puts 'Error adding comment!'
          puts @point_comment.errors.full_messages
        end
      else
        puts 'Error declining point!'
        puts point.errors.full_messages
      end
    end
  end
end
