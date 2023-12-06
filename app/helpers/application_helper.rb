require 'httparty'

# app/helpers/application_helper.rb
module ApplicationHelper
  def annotate_service_path(service)
    service_path(service) + '/annotate'
  end

  def report_spam(text, type)
    HTTParty.post('https://api.tosdr.org/spam/v1/', body: {
      text: text,
      type: type
    },
    headers: {
      apikey: ENV['TOSDR_API_KEY']
    })
  end

  def rank_badge(user)
    bot_icon = fa_icon 'robot', text: ' Bot'
    admin_icon = fa_icon 'tools', text: ' Staff'
    banned_icon = fa_icon 'ban', text: ' Suspended'
    curator_icon = fa_icon 'hands-helping', text: ' Curator'
    
    id = user
    user = User.find(user.to_i) if id.instance_of? String
    return if user.nil?

    if user.deactivated?
      raw link_to(banned_icon, 'https://to.tosdr.org/banned', target: '_blank', title: 'This user has been suspended', class: 'label label-danger')
    elsif user.bot?
      raw link_to(bot_icon, 'https://to.tosdr.org/bot', target: '_blank', title: 'This user is an official ToS;DR Bot', class: 'label label-warning')
    elsif user.admin?
      raw link_to(admin_icon, 'https://to.tosdr.org/about', target: '_blank', title: 'This user is a ToS;DR Team member', class: 'label label-danger')
    elsif user.curator?
      raw link_to(curator_icon, 'https://to.tosdr.org/8dd5k', target: '_blank', title: 'This user is a phoenix curator', class: 'label label-primary')
    end
  end

  def status_badge(status)
    approved_icon = fa_icon 'check', text: ' APPROVED'
    approved_nf_icon = fa_icon 'check', text: ' QUOTE NOT FOUND'
    declined_icon = fa_icon 'times', text: ' DECLINED'
    pending_icon = fa_icon 'clock', text: ' PENDING'
    pending_nf_icon = fa_icon 'clock', text: ' QUOTE NOT FOUND'
    change_icon = fa_icon 'edit', text: ' CHANGES REQUESTED'
    draft_icon = fa_icon 'pencil-ruler', text: ' DRAFT'

    return if status.nil?

    case status
    when 'approved'
      raw content_tag(:span, approved_icon, class: 'label label-success')
    when 'approved-not-found'
      raw content_tag(:span, approved_nf_icon, class: 'label label-success')
    when 'declined'
      raw content_tag(:span, declined_icon, class: 'label label-danger')
    when 'changes-requested'
      raw content_tag(:span, change_icon, class: 'label label-warning')
    when 'pending'
      raw content_tag(:span, pending_icon, class: 'label label-info')
    when 'pending-not-found'
      raw content_tag(:span, pending_nf_icon, class: 'label label-info')
    when 'draft'
      raw content_tag(:span, draft_icon, class: 'label label-primary')
    else
      status
    end
  end

  def username(user_str)
    invalid_icon = fa_icon 'user-times', text: 'Deleted'
    unless user_str
      return raw link_to(invalid_icon, '/users/edit', target: '_blank', title: 'This user has deleted their account', class: 'label label-default')
    end

    return user_str.username || 'user ' + user_str.id.to_s if user_str.instance_of? User

    user_id = user_str.to_i
    return 'you' if user_id && current_user && user_id == current_user.id

    user = User.find(user_id)
    return raw user.username + ' <sup>(' + user.id.to_s + ')</sup>' || 'user ' + user.id.to_s if user&.username && user&.id

    user_str
  end

  def hide_tags(snippet)
    sanitize(
      snippet
      .gsub(/&(.*?);/, '&amp;\1;')
      .gsub(/<(.*?)>/, '<span class="hiddenTag">&lt;\1&gt;</span>')
    ).html_safe
  end

  def format_figures(figure, first: true)
    if first
      figure.nil? ? 'No changes recorded' : figure.first
    else
      figure.nil? ? 'No changes recorded' : figure.second
    end
  end
end
