class Point < ApplicationRecord
 has_paper_trail
 belongs_to :user, optional: true
 belongs_to :service
 has_many :reasons, dependent: :destroy
 belongs_to :topic

 validates :title, presence: true
 validates :title, length: { in: 5..140 }
 validates :source, presence: true
 validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed", "draft"], allow_nil: false }
 validates :analysis, presence: true
 validates :rating, presence: true
 validates :rating, numericality: true

 # after_save :create_associated_reason

### CLASS METHODS #####
def self.search_points_by_multiple(query)
  Point.joins(:service).where("services.name ILIKE ? or points.status ILIKE ?", "%#{query}%", "%#{query}%")
end

def self.search_points_by_topic(query)
  Point.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
end

### METHODS FOR MANAGING VERSIONS ###

def figures_for_versions_object(point)
    result = {}
    self.versions.each do |v|
      v.changeset['reason'].nil? ? reason = "No reason provided for previous changes" : reason = v.changeset["reason"].second
      time = v.changeset["updated_at"].second.time.strftime("%d/%m/%y - %H:%M")
      event = v.event == "create" ? "Analysis created" : "Analysis updated"

      analysis = v.changeset["analysis"]
      status = v.changeset["status"]

    result[v.id.to_s] = {
          event: event,
          previous_analysis: format_figures(analysis),
          updated_analysis: format_figures(analysis, first = false),
          previous_status: format_figures(status),
          updated_status: format_figures(status, first = false),
          reason: reason,
          time: time
        }
    end
    result

    # the goal of this is to store pre-formatted versions in a json object to
    # be called upon in the view on an as-needed basis
    # each hash inside of the json object represents one version
    # here is an example of a version that tracked a change to the status:
    # --> "29"=>{
            # :event=>"Analysis updated",
            # :previous_analysis=>"dfasdfasdf",       :updated_analysis=>"ailhfiwaehfoiahw", :previous_status=>"approved",
            # :updated_status=>"declined",
            # :reason=>"ffdfg",
            # :time=>"20/03/18 - 20:50"}
    # here is an example of a version that tracked a change to the analysis:
    # --> "27"=>{:event=>"Analysis updated",
                # :previous_analysis=>"No changes recorded", :updated_analysis=>"No changes recorded", :previous_status=>"declined",
                # :updated_status=>"approved",
                # :reason=>"stufff23456",
                # :time=>"20/03/18 - 20:19"}
    # it is my opinion that this will be easier to manipulate in the view
    # this also potentially removes our need to have a separately stored reason object, if papertrail is tracking all changes to the reasons
end

  def format_figures(figure, first = true)
    if first
      figure.nil? ? "No changes recorded" : figure.first
    else
      figure.nil? ? "No changes recorded" : figure.second
    end
  end

end
