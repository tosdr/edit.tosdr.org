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

  def rank_badge (user)
  	bot_icon = fa_icon "robot", text: " Bot"
  	admin_icon = fa_icon "tools", text: " Staff"
  	curator_icon = fa_icon "hands-helping", text: " Curator"

    if !user.nil?
    	if(user.bot?)
    		return raw link_to(bot_icon, "https://to.tosdr.org/bot", target: "_blank", title: "This user is an official ToS;DR Bot", class: "label label-warning");
    	end
    	if(user.admin?)
    		return raw link_to(admin_icon, "https://tosdr.org/about", target: "_blank", title: "This user is a ToS;DR Team member", class: "label label-danger");
    	end
    	if(user.curator?)
    		return raw link_to(curator_icon, "https://forum.tosdr.org/t/105", target: "_blank", title: "This user is a phoenix curator", class: "label label-primary");
    	end
    end
  end

  def status_badge (status)
  	approved_icon = fa_icon "check", text: " APPROVED"
  	approved_nf_icon = fa_icon "check", text: " QUOTE NOT FOUND"
  	declined_icon = fa_icon "times", text: " DECLINED"
  	pending_icon = fa_icon "clock", text: " PENDING"
  	pending_nf_icon = fa_icon "clock", text: " QUOTE NOT FOUND"
  	change_icon = fa_icon "edit", text: " CHANGES REQUESTED"
  	draft_icon = fa_icon "pencil-ruler", text: " DRAFT"

    if !status.nil?
    	if(status == "approved")
    		return raw content_tag(:span, approved_icon, class: "label label-success");
    	end
    	if(status == "approved-not-found")
    		return raw content_tag(:span, approved_nf_icon, class: "label label-success");
    	end
    	if(status == "declined")
    		return raw content_tag(:span, declined_icon, class: "label label-danger");
    	end
    	if(status == "changes-requested")
    		return raw content_tag(:span, change_icon, class: "label label-warning");
    	end
    	if(status == "pending")
    		return raw content_tag(:span, pending_icon, class: "label label-info");
    	end
    	if(status == "pending-not-found")
    		return raw content_tag(:span, pending_nf_icon, class: "label label-info");
    	end
    	if(status == "draft")
    		return raw content_tag(:span, draft_icon, class: "label label-primary");
    	end
		return status
    end
  end

  def username (user_str)
    # puts user_str
  	invalid_icon = fa_icon "user-times", text: "Deleted"
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
      return raw link_to(invalid_icon, "/users/edit", target: "_blank", title: "This user has deleted his account", class: "label label-default");
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
