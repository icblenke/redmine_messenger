module UserMessengerHelper
  
  def issue_status_to_select
    options = []
    options << [l(:messenger_options_statuses_dont_change, nil)]
    IssueStatus.all.each { |x| options << [x.name.downcase, x.id] }
    options
  end
  
end
