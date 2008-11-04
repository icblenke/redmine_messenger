class UserMessengerController < ApplicationController

  def index    
    user = User.current
    
    @groups = {}

    RedmineMessenger::Base.commands.each_value do |cmd|
      @groups[cmd.group] ||= []
      @groups[cmd.group] << cmd
    end
    
    @user_messenger = UserMessenger.find_by_user_id(user.id) 
    @user_messenger ||= UserMessenger.new
    if request.post?
      @user_messenger.user = user
      @user_messenger.messenger_id = params[:user_messenger][:messenger_id]      
      @user_messenger.resume_when_become_online = params[:user_messenger][:resume_when_become_online]
      @user_messenger.pause_when_become_offline_or_away = params[:user_messenger][:pause_when_become_offline_or_away]
      @user_messenger.issue_status_when_starting_timer_id = params[:user_messenger][:issue_status_when_starting_timer_id]
      @user_messenger.issue_status_when_finishing_timer_with_full_ratio_id = params[:user_messenger][:issue_status_when_finishing_timer_with_full_ratio_id]
      @user_messenger.issue_status_when_finishing_timer_id = params[:user_messenger][:issue_status_when_finishing_timer_id]
      @user_messenger.messenger_notifications_instead_of_emails = params[:user_messenger][:messenger_notifications_instead_of_emails]
      @user_messenger.assigning_issue_when_starting_timer = params[:user_messenger][:assigning_issue_when_starting_timer]
      if @user_messenger.save
        if @user_messenger.verification_code
            flash[:notice] = l(:messenger_controller_notice_updated_with_code, @user_messenger.verification_code)
        else
            flash[:notice] = l(:messenger_controller_notice_updated, @user_messenger.verification_code)
        end
        redirect_to :action => 'index'
      end    
    end
  end
  
end