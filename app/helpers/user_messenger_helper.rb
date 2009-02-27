module UserMessengerHelper
  
  def issue_status_to_select
    options = []
    options << [l(:messenger_options_statuses_dont_change, nil)]
    IssueStatus.all.each do |x| 
      name = l("default_issue_status_#{x.name.downcase}".to_sym, x.name.downcase).downcase
      options << [name, x.id]      
    end
    options    
  end

end
