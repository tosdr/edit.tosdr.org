module ApplicationHelper
  def username (user_id)
    if user_id
      user = User.find_by_id(user_id)
      return user.username || 'user ' + user.id.to_s
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
