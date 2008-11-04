class IssuesMessenger < RedmineMessenger::Base

  register_handler :issues do |cmd|
    cmd.group :issues
    cmd.param :name, :type => :string, :required => false, :greedy => true
  end
  
  register_handler :issue do |cmd|
    cmd.group :issues
    cmd.param :issue_id, :type => :integer, :required => true   
  end
  
  register_handler :comment do |cmd|
    cmd.group :issues
    cmd.param :issue_id, :type => :integer, :required => true
    cmd.param :note, :type => :string, :greedy => true, :required => true
  end

  def issues(user, params = {})
    # TODO don't show finished issues    
    unless params[:name].blank?
      issues = Issue.find(:all, :conditions => ["lower(subject) like lower(?)", "%#{params[:name]}%"])
      return l(:messenger_command_issues_not_found, params[:name]) if issues.empty?
    else
      issues = Issue.find_all_by_assigned_to_id(user.user_id)
      return l(:messenger_command_issues_assigned_not_found) if issues.empty?
    end
    
    projects = {}
    
    issues.each do |issue|
      projects[issue.project.name] ||= []
      projects[issue.project.name] << issue
    end
    
    responce = l(:messenger_command_issues_found, issues.length) << "\n\n"
    
    projects.each do |project, issues|
      responce << project.humanize << ":\n"
      issues.each do |issue|
        responce << "    \##{issue.id} #{issue.subject}\n" 
      end
      responce << "\n"
    end
     
    responce        
  end
  
  def issue(user, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      responce = "#{issue.project.name.humanize}: \##{issue.id} #{issue.subject} (" << l(:messenger_command_issue_status, issue.status.name.downcase)
      responce << ", " << l(:messenger_command_issue_assigned_to, issue.assigned_to.login.to_s) if issue.assigned_to
      responce << ")"
      responce << "\n\n" << issue.description if issue.description and issue.description.size > 1
      responce
    else
      l(:messenger_command_issue_not_found)
    end
  end
  
  def comment(user, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      journal = issue.init_journal(user.user, params[:note])
      
      if journal.save
        Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
        l(:messenger_command_comment_commented)
      else 
        l(:messenger_command_comment_not_commented)
      end
    else
      l(:messenger_command_issue_not_found)
    end
  end

end