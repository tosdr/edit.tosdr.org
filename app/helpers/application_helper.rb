module ApplicationHelper
  def annotate_service_path (service)
    service_path(service) + '/annotate'
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

  def format_time(time)
    time.strftime("%d/%m/%y - %H:%M")
  end

  def format_figures(figure, first = true)
    if first
      figure.nil? ? "No changes recorded" : figure.first
    else
      figure.nil? ? "No changes recorded" : figure.second
    end
  end
end
