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

  register_status_handler :status_available, :available
  register_status_handler :status_unavailable, :unavailable
    
  def status_available(messenger, status)
    if messenger.resume_when_become_online? and messenger.timer_running? and messenger.timer_paused_because_of_status_change?
      messenger.timer_resume
      ll(messenger.language, :messenger_command_timers_resumed_because_of_status_change, messenger.issue.subject)
    end
  end
  
  def status_unavailable(messenger, status)
    if messenger.pause_when_become_offline_or_away? and messenger.timer_running? and not messenger.timer_paused?
      messenger.timer_pause(nil, true)
      ll(messenger.language, :messenger_command_timers_paused_because_of_status_change, messenger.issue.subject)
    end
  end
  
  def start(messenger, params = {})
    if issue = Issue.find_by_id(params[:issue_id])          
      if messenger.timer_running?
        if issue != messenger.issue
          messenger.timer_finish
          messenger.timer_start(issue, params[:note])
          status(messenger, params)
        elsif messenger.timer_paused?
          messenger.timer_resume(params[:note])
          status(messenger, params)
        else
          status(messenger, params)
        end
      else
        messenger.timer_start(issue, params[:note])
        status(messenger, params)
      end
    else
      ll(messenger.language, :messenger_command_timers_issue_not_found)
    end
  end
  
  def resume(messenger, params = {})
    if messenger.timer_running?
      if messenger.timer_paused?
        messenger.timer_resume(params[:note])
        ll(messenger.language, :messenger_command_timers_resumed, messenger.issue.subject)
      else
        ll(messenger.language, :messenger_command_timers_not_resumed, messenger.issue.subject)
      end
    else
      ll(messenger.language, :messenger_command_timers_not_running)
    end
  end
  
  def pause(messenger, params = {})
    if messenger.timer_running?
      unless messenger.timer_paused?
        messenger.timer_pause(params[:note])
        ll(messenger.language, :messenger_command_timers_paused, messenger.issue.subject)
      else
        if messenger.timer_paused_because_of_status_change?
          messenger.timer_pause(params[:note])
          ll(messenger.language, :messenger_command_timers_paused, messenger.issue.subject)
        else
          ll(messenger.language, :messenger_command_timers_not_paused, messenger.issue.subject)
        end
      end
    else
      ll(messenger.language, :messenger_command_timers_not_running)
    end
  end
  
  def cancel(messenger, params = {})
    if messenger.timer_running?
      messenger.timer_cancel
      ll(messenger.language, :messenger_command_timers_cancelled, messenger.issue.subject)
    else
      ll(messenger.language, :messenger_command_timers_not_running)
    end
  end
  
  def finish(messenger, params = {})
    if messenger.timer_running?
      issue = messenger.issue
      if messenger.timer_finish(params[:done_ratio], params[:note])
        ll(messenger.language, :messenger_command_timers_finished, issue.subject)
      else
        ll(messenger.language, :messenger_command_timers_not_finished, issue.subject)
      end
    else
      ll(messenger.language, :messenger_command_timers_not_running)
    end
  end
  
  def note(messenger, params = {})
    if messenger.timer_running?
      messenger.timer_add_note(params[:note])
      ll(messenger.language, :messenger_command_timers_noted, messenger.issue.subject)
    else
      ll(messenger.language, :messenger_command_timers_not_running)
    end
  end
  
  def status(messenger, params = {})
    if params[:issue_id] and params[:issue_id] > 0 and messenger.issue_id != params[:issue_id]
      if issue = Issue.find_by_id(params[:issue_id])
        stats = stats_for_issue(issue, messenger.user_id)
        responce = ll(messenger.language, :messenger_command_timers_not_running_for_that_issue, issue.subject) << "\n"
        responce << status_for_issue(messenger, stats)
        responce
      else
        ll(messenger.language, :messenger_command_timers_issue_not_found)
      end
    else
      if messenger.timer_running?
        stats = stats_for_issue(messenger.issue, messenger.user_id, messenger.timer_to_hours)
        if messenger.timer_paused?
          responce = ll(messenger.language, :messenger_command_timers_paused_status, messenger.issue.subject) << "\n"
        else
          responce = ll(messenger.language, :messenger_command_timers_running_status, messenger.issue.subject, messenger.timer_to_minutes) << "\n"
        end
        responce << status_for_issue(messenger, stats)
        responce
      else
        ll(messenger.language, :messenger_command_timers_not_running)
      end
    end
  end
  
  private 

  def status_for_issue(messenger, stats)
    logged_by_you_today, logged_by_you, logged_by_all, rest_time, estimated_time, done_ratio = stats    
    responce = ll(messenger.language, :messenger_command_timers_running_stats_time, logged_by_you_today, logged_by_you, logged_by_all) << "\n"
    if estimated_time > 0
      responce << ll(messenger.language, :messenger_command_timers_running_stats_done_with_estimation, done_ratio, rest_time, estimated_time)
    else
      responce << ll(messenger.language, :messenger_command_timers_running_stats_done, done_ratio)
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