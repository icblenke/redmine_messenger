class IssuesMessenger < RedmineMessenger::Base

  register_handler :issues do |cmd|
    cmd.group :issues
    cmd.param :name, :type => :string, :required => false, :greedy => true
  end
  
  register_handler :all_issues do |cmd|
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
  
  register_handler :assign do |cmd|
    cmd.group :issues
    cmd.param :issue_id, :type => :integer, :required => true
    cmd.param :user, :type => :string, :required => true
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end

  def issues(user, params = {})  
    unless params[:name].blank?
      issues = Issue.find(:all, :include => [:status], :conditions => ["lower(issues.subject) like lower(?) and issue_statuses.is_closed = ?", "%#{params[:name]}%", false])
      return l(:messenger_command_issues_not_found, params[:name]) if issues.empty?
    else
      issues = Issue.find(:all, :include => [:status], :conditions => ["issues.assigned_to_id = ? and issue_statuses.is_closed = ?", user.user_id, false])
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
  
  def assign(user, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      return l(:messenger_command_issue_not_assigned_to_you) unless issue.assigned_to == user.user      
      
      user_assing_to = User.find_by_login(params[:user])
      
      unless user_assing_to
        return l(:messenger_command_assing_user_not_found, params[:user])
      end
      
      return l(:messenger_command_assing_already_assigned, user_assing_to.login) if user_assing_to == user.user
      
      unless params[:note].blank?
        unless journal(user.user, issue, params[:note])
          return l(:messenger_command_comment_not_commented)
        end
      end
      
      issue.assigned_to = user_assing_to
      
      if issue.save
        l(:messenger_command_assing_assigned, user_assing_to.login)
      else
        l(:messenger_command_assing_not_assigned, user_assing_to.login)
      end
    else
      l(:messenger_command_issue_not_found)
    end
  end
  
  def comment(user, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      return l(:messenger_command_issue_not_assigned_to_you) unless issue.assigned_to == user.user
      
      if journal(user.user, issue, params[:note])
        l(:messenger_command_comment_commented)
      else 
        l(:messenger_command_comment_not_commented)
      end
    else
      l(:messenger_command_issue_not_found)
    end
  end
  
  private
  
  def journal(user, issue, notes)
    journal = issue.init_journal(user, notes)

    if journal.save
      Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
      true
    else
      false
    end
  end

end