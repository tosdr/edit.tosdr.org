module ApplicationHelper
  def annotate_service_path (service)
    service_path(service) + '/annotate'
  end

  def point_comments_path (topic)
    point_point_comments_path(topic)
  end

  def service_comments_path (service)
    service_service_comments_path(service)
  end

  def case_comments_path (case_)
    case_case_comments_path(case_)
  end

  def document_comments_path (document)
    document_document_comments_path(document)
  end

  def topic_comments_path (topic)
    topic_topic_comments_path(topic)
  end
  
  def RankBadge (user)
	if(user.admin?)
		return raw link_to("ToS;DR", "https://beta.tosdr.org/about", target: "_blank", title: "This user is a ToS;DR Team member", class: "label label-danger");
	end
	if(user.curator?)
		return raw link_to("Curator", "https://forum.tosdr.org/t/105", target: "_blank", title: "This user is a phoenix curator", class: "label label-primary");
	end
  end

  def username (user_str)
    # puts user_str
    if user_str
      if user_str.instance_of? User
        if user_str.username
          return user_str.username
        end
        return 'user ' + user_str.id.to_s
      end
      user_id = user_str.to_i
      if user_id
        if current_user && user_id == current_user.id
          return 'you'
        end
        user = User.find_by_id(user_id)
        if user
          return user.username || 'user ' + user.id.to_s
        end
      end
      return user_str
    else
      return 'someone'
    end
  end

  def hide_tags(snippet)
    sanitize(
      snippet
      .gsub(/&(.*?);/, '&amp;\1;')
      .gsub(/<(.*?)>/, '<span class="hiddenTag">&lt;\1&gt;</span>')
    ).html_safe
  end

  def format_figures(figure, first = true)
    if first
      figure.nil? ? "No changes recorded" : figure.first
    else
      figure.nil? ? "No changes recorded" : figure.second
    end
  end
end
