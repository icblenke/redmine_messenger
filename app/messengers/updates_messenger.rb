class UpdatesMessenger < RedmineMessenger::Base

  unless defined?(Redmine::I18n)
    include MessengerI18nPatch
  end

  register_handler :update do |cmd|
    cmd.group :updates
    cmd.param :message, :type => :string, :required => true, :greedy => true
  end
    
  register_handler :updates do |cmd|
    cmd.group :updates
    cmd.param :count, :type => :integer, :required => false
  end
 
  def update(messenger, params = {})
    message = params[:message]
    options = {:message => message.strip, :user_id => messenger.user_id, :created_on => Date.today}
    Status.create(options) unless message.blank?
    updates(messenger)
  end

  def updates(messenger, params = {})
    #set the count of status messages to be returned
    params[:count] ||= 5
    responce = "Last #{params[:count]} Status"

    #fetch the count status messages
    Status.find(:all, :limit => count, :order => "id desc").each do |status|
      responce << "#{status.message} - #{status.user.name}(#{status.created_on})\n\n"
    end
    responce
  end
  
  private

end
