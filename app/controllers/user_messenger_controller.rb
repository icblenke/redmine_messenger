class UserMessengerController < ApplicationController

  def index    
    user = User.current
    @user_messenger = UserMessenger.find_by_user_id(user.id) 
    @user_messenger ||= UserMessenger.new
    if request.post?
      @user_messenger.user = user
      @user_messenger.messenger_id = params[:user_messenger][:messenger_id]
      if @user_messenger.save
        if @user_messenger.verification_code
            flash[:notice] = l(:notice_messenger_updated_with_code, @user_messenger.verification_code)
        else
            flash[:notice] = l(:notice_messenger_updated, @user_messenger.verification_code)
        end
        redirect_to :action => 'index'
        return
      end    
    end
  end
  
end