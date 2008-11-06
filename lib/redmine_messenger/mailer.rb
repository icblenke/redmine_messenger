class Mailer < ActionMailer::Base

  alias_method :create_without_messenger!, :create!
  
  def create!(method_name, *parameters)
    mail = create_without_messenger!(method_name, *parameters)
    
    return mail if mail.to.nil?
    
    message = nil
    
    mail.to.each do |email|  
      if user = User.find_by_mail(email) and messenger = UserMessenger.find_by_user_id(user.id) and messenger.messenger_notifications?
        if message.nil?
          footer = Setting[:emails_footer].gsub(/\r\n/, "\n")
          message = mail.body.gsub(/#{footer}.*/m, "").gsub(/[-]{3,}/, "\n").gsub(/[\n]{3,}/, "\n\n").strip
        end        
        RedmineMessenger::Messenger.send_message(messenger.messenger_id, message)
      end
    end

    mail
  end
    
end
