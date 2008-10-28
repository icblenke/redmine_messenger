class IssuesMessenger < RedmineMessenger::Base

  register_handler :pause do |cmd|
    cmd.group :timers
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end
  
  register_handler :resume do |cmd|
    cmd.group :timers
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end
  
  register_handler :finish do |cmd|
    cmd.group :timers
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end
  
  register_handler :cancel do |cmd|
    cmd.group :timers
  end
  
  register_handler :note do |cmd|
    cmd.group :timers
    cmd.param :note, :type => :string, :greedy => true
  end
  
  register_handler :status do |cmd|
    cmd.group :timers
  end
  
  register_handler :start do |cmd|
    cmd.group :timers
    cmd.param :issue_id, :type => :integer
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end

  def start(user, params = {})
    if user.timer_running?
      user.timer_finish
    end
    if issue = Issue.find_by_id(params[:issue_id])      
      user.timer_start(issue, params[:note])
      l(:messenger_command_timers_started, issue.subject)
    else
      l(:messenger_command_timers_issue_not_found)
    end
  end
  
  def resume(user, params = {})
    if user.timer_running? 
      if user.timer_paused?
        user.timer_resume(params[:note])
        l(:messenger_command_timers_resumed, user.issue.subject)
      else
        l(:messenger_command_timers_not_resumed, user.issue.subject)
      end
    else
      l(:messenger_command_timers_not_running) 
    end
  end
  
  def pause(user, params = {})
    if user.timer_running? 
      unless user.timer_paused?
        user.timer_pause(params[:note])
        l(:messenger_command_timers_paused, user.issue.subject)
      else
        l(:messenger_command_timers_not_paused, user.issue.subject)
      end
    else
      l(:messenger_command_timers_not_running) 
    end
  end
  
  def cancel(user, params = {})
    if user.timer_running? 
      user.timer_cancel
      l(:messenger_command_timers_cancelled, user.issue.subject)
    else
      l(:messenger_command_timers_not_running) 
    end
  end
  
  def finish(user, params = {})
    if user.timer_running? 
      issue = user.issue
      if user.timer_finish(params[:note])
        l(:messenger_command_timers_finished, issue.subject)
      else
        l(:messenger_command_timers_not_finished, issue.subject)
      end
    else
      l(:messenger_command_timers_not_running) 
    end
  end
  
  def note(user, params = {})
    if user.timer_running?
      user.timer_add_note(params[:note])
      l(:messenger_command_timers_noted, user.issue.subject)
    else
      l(:messenger_command_timers_not_running) 
    end
  end
  
  def status(user, params = {})
    if user.timer_running?
      l(:messenger_command_timers_running_status, user.issue.subject, user.timer_to_minutes)
    else
      l(:messenger_command_timers_not_running) 
    end
  end
   
end