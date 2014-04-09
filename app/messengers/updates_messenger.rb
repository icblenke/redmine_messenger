class UpdatesMessenger < RedmineMessenger::Base

  unless defined?(Redmine::I18n)
    include MessengerI18nPatch
  end

  register_handler :update do |cmd|
    cmd.group :updates
    cmd.param :message, :type => :string, :required => true, :greedy => true
  end
    
  register_handler :list do |cmd|
    cmd.group :updates
    cmd.param :count, :type => :integer, :required => false
  end
 
  def update(messenger, params = {})
    message = params[:message]
    options = {:message => message.strip, :user_id => messenger.user_id, :created_on => Date.today}
    s = Status.create(options) unless message.blank?
    messengers = UserMessenger.find(:all, :conditions => "user_id != #{messenger.user_id} and verification_code is NULL")
    messengers.collect{|m| m.messenger_id}.each do |m_id|
      RedmineMessenger::Messenger.send_message(m_id, s.message_with_details)
    end
    list(messenger)
  end

  def list(messenger, params = {})
    #set the count of status messages to be returned
    count = (params.blank? || params[:count].blank? ? 5 : params[:count])
    count = count.to_i
    responce = "Last #{count} Status\n\n"

    #fetch the count status messages
    project_updates  = Status.recent_updates_for(nil)
    messenger_updates = Status.find(:all, :order => "id desc", :conditions => "project_id is NULL")
    updates = project_updates + messenger_updates
    (updates.sort{|a,b| b.created_at <=> a.created_at})[0..(count -1)].each do |status|
      responce << status.message_with_details 
    end
    responce
  end
  
  private

end
