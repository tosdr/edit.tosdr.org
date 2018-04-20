module ApplicationHelper

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
