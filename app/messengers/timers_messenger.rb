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
    cmd.param :done_ratio, :type => :integer, :required => false
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
    cmd.param :issue_id, :type => :integer, :required => false
  end
  
  register_handler :start do |cmd|
    cmd.group :timers
    cmd.param :issue_id, :type => :integer
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end

  def start(user, params = {})
    if issue = Issue.find_by_id(params[:issue_id])          
      if user.timer_running?
        if issue != user.issue
          user.timer_finish
          user.timer_start(issue, params[:note])
          status(user, params)
        elsif user.timer_paused?
          user.timer_resume(params[:note])
          status(user, params)
        else
          status(user, params)
        end
      else
        user.timer_start(issue, params[:note])
        status(user, params)
      end
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
      if user.timer_finish(params[:done_ratio], params[:note])
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
    if params[:issue_id] and params[:issue_id] > 0 and user.issue_id != params[:issue_id]
      if issue = Issue.find_by_id(params[:issue_id])
        stats = stats_for_issue(issue, user.user_id)
        responce = l(:messenger_command_timers_not_running_for_that_issue, issue.subject) << "\n"
        responce << status_for_issue(stats)
        responce
      else
        l(:messenger_command_timers_issue_not_found)
      end
    else
      if user.timer_running?
        stats = stats_for_issue(user.issue, user.user_id, user.timer_to_hours)
        responce = l(:messenger_command_timers_running_status, user.issue.subject, user.timer_to_minutes) << "\n" 
        responce << status_for_issue(stats)
        responce
      else
        l(:messenger_command_timers_not_running) 
      end
    end
  end
  
  private 

  def status_for_issue(stats)
    logged_by_you_today, logged_by_you, logged_by_all, rest_time, estimated_time, done_ratio = stats    
    responce = l(:messenger_command_timers_running_stats_time, logged_by_you_today, logged_by_you, logged_by_all) << "\n"
    if estimated_time > 0
      responce << l(:messenger_command_timers_running_stats_done_with_estimation, done_ratio, rest_time, estimated_time)
    else
      responce << l(:messenger_command_timers_running_stats_done, done_ratio)
    end
    responce
  end
  
  def stats_for_issue(issue, user_id, timer_hours = 0)
    logged_by_you, logged_by_you_today, logged_by_all = timer_hours, timer_hours, timer_hours
    estimated_time = issue.estimated_hours || 0
    issue.time_entries.each do |time_entry|
      logged_by_all += time_entry.hours
      if time_entry.user_id == user_id
        logged_by_you += time_entry.hours 
        logged_by_you_today += time_entry.hours if time_entry.spent_on == Time.now.to_date
      end
    end
    rest_time = (estimated_time > logged_by_all) ? estimated_time - logged_by_all : 0
    done_ratio = issue.done_ratio
    [logged_by_you_today, logged_by_you, logged_by_all, rest_time, estimated_time, done_ratio]
  end
   
end