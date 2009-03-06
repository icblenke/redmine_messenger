module UserMessengerHelper
  
  def issue_status_to_select
    options = []
    options << [l(:messenger_options_statuses_dont_change)]
    IssueStatus.all.each do |x| 
      options << [x.name.downcase, x.id]      
    end
    options    
  end

end
