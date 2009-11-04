class IssuesMessenger < RedmineMessenger::Base

  unless defined?(Redmine::I18n)
    include MessengerI18nPatch
  end

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
  
  register_handler :assign do |cmd|
    cmd.group :issues
    cmd.param :issue_id, :type => :integer, :required => true
    cmd.param :user, :type => :string, :required => true
    cmd.param :note, :type => :string, :greedy => true, :required => false
  end

  def issues(messenger, params = {})
    unless params[:name].blank?
      issues = Issue.find(:all, :include => [:status], :conditions => ["lower(issues.subject) like lower(?) and issue_statuses.is_closed = ?", "%#{params[:name]}%", false])
      return ll(messenger.language, :messenger_command_issues_not_found, :command => params[:name]) if issues.empty?
    else
      issues = Issue.find(:all, :include => [:status], :conditions => ["issues.assigned_to_id = ? and issue_statuses.is_closed = ?", messenger.user_id, false])
      return ll(messenger.language, :messenger_command_issues_assigned_not_found) if issues.empty?
    end
    
    projects = {}

    
    issues.each do |issue|
      projects[issue.project.name] ||= []
      projects[issue.project.name] << issue
    end
    
    responce = ll(messenger.language, :messenger_command_issues_found, :found => issues.length) << "\n\n"
    ActiveRecord::Base.logger.error "sdhkjsadhkjs hdkj shakd hks dhkjs hd"

    projects.each do |project, issues|
      responce << project.humanize << ":\n"
      issues.each do |issue|
        responce << "    \##{issue.id} #{issue.subject}\n" 
      end
      responce << "\n"
    end
     
    responce        
  end
  
  def issue(messenger, params = {})
    if issue = Issue.find_by_id(params[:issue_id])
      return ll(messenger.language, :messenger_command_issue_not_assignable_user) unless issue.assignable_users.include?(messenger.user)
      responce = "#{issue.project.name.humanize}: \##{issue.id} #{issue.subject} (" << ll(messenger.language, :messenger_command_issue_status, :status => issue.status.name.downcase)
      responce << ", " << ll(messenger.language, :messenger_command_issue_assigned_to, :login => issue.assigned_to.login.to_s) if issue.assigned_to
      responce << ")"
      responce << "\n\n" << issue.description if issue.description and issue.description.size > 1
      responce
    else
      ll(messenger.language, :messenger_command_issue_not_found)
    end
  end
  
  def assign(messenger, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      return ll(messenger.language, :messenger_command_issue_not_assigned_to_you) unless issue.assigned_to == messenger.user      
      
      user_assing_to = User.find_by_login(params[:user])
      
      unless user_assing_to
        return ll(messenger.language, :messenger_command_assing_user_not_found, :login => params[:user])
      end
      
      return ll(messenger.language, :messenger_command_assing_not_assignable_user, :login => user_assing_to.login) unless issue.assignable_users.include?(user_assing_to)
      return ll(messenger.language, :messenger_command_assing_already_assigned, :login => user_assing_to.login) if user_assing_to == messenger.user
      
      unless params[:note].blank?
        unless journal(messenger.user, issue, params[:note])
          return ll(messenger.language, :messenger_command_comment_not_commented)
        end
      end
      
      issue.assigned_to = user_assing_to
      
      if issue.save
        ll(messenger.language, :messenger_command_assing_assigned, :login => user_assing_to.login)
      else
        ll(messenger.language, :messenger_command_assing_not_assigned, :login => user_assing_to.login)
      end
    else
      ll(messenger.language, :messenger_command_issue_not_found)
    end
  end
  
  def comment(messenger, params = {})
    if issue = Issue.find_by_id(params[:issue_id]) 
      return ll(messenger.language, :messenger_command_issue_not_assignable_user) unless issue.assignable_users.include?(messenger.user)
      
      if journal(messenger.user, issue, params[:note])
        ll(messenger.language, :messenger_command_comment_commented)
      else 
        ll(messenger.language, :messenger_command_comment_not_commented)
      end
    else
      ll(messenger.language, :messenger_command_issue_not_found)
    end
  end
  
  private
  
  def journal(messenger, issue, notes)
    journal = issue.init_journal(messenger, notes)

    if journal.save
      Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
      true
    else
      false
    end
  end

end
