class IssuesMessenger < RedmineMessenger::Base

  register_message_listener :issues do |cmd|
    cmd.group :issues
  end
  
  register_message_listener :issue do |cmd|
    cmd.group :issues
    cmd.param :issue_id, :type => :integer, :required => true
  end

  def issues(user, params = {})
    if issues = Issue.find_by_assigned_to_id(user.user_id)
      responce = ""
      issues.each do |issue|
        responce << "\##{issue.id} #{issue.project.name} - #{issue.subject}\n"
      end
      responce
    else
      l(:messenger_command_issues_not_found)
    end
  end
  
  def issue(user, params = {})   
    if issue = Issue.find_by_id(params[:issue_id]) 
      responce = "\##{issue.id} #{issue.project.name} - #{issue.subject} (#{issue.status.name})"
      responce << l(:messenger_command_issue_assigned_to) << issue.assigned_to.login << "\n" if issue.assigned_to
      responce << issue.description if issue.description and issue.description.size > 1
      responce
    else
      l(:messenger_command_issue_not_found)
    end
  end

#  General:
#    hello
#    show (entry|entries|timer|timers|projects)
#
#Entries:
#    log
#    unlog
#
#Timers:
#    pause
#    resume
#    start
#    finish
#    cancel
#    note

#  Show full details of the entry by entry id.
#    > show entry <entry id>

#Show things.  (type: 'help show <subcommand>').
#    > show entries
#    > show entry <entry id>
#    > show timers
#    > show timer <timer id>
#    > show projects

#  Show last 50 entries by you.
#    > show entries

#  Start timer for the billing code.
#    > start <billing code>

end