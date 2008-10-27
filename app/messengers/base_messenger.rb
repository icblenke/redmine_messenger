class BaseMessenger < RedmineMessenger::Base

  def verify(mid, code)
    if user = UserMessenger.find_by_messenger_id(mid)
      if user.verify(code)
        responce = l(:messenger_verify_user_verified)
      else
        responce = l(:messenger_verify_wrong_code)
      end
    else
      responce = l(:messenger_verify_user_not_registered)
    end        
    ::RedmineMessenger::Messenger.send_message(mid, responce)
  end
      
  def help(mid, body)
    body = body.gsub(/help/, "").strip
        
    commands = ::RedmineMessenger::Base.commands
    
    if not body.blank? and command = commands[body.to_sym]
      responce = l(:messenger_help_header_long, command.to_s) << "\n\n"
      responce << l("messenger_help_command_#{command.command.to_s}_long".to_sym)
      responce  << "\n\n" << l(:messenger_help_footer_long, command.to_s)
    else
      responce = l(:messenger_help_header_short) << "\n\n"

      groups = {}
      
      commands.each_value do |cmd|
        groups[cmd.group] ||= [] 
        groups[cmd.group] << cmd
      end
      
      groups.each do |grp, cmds|
        responce << l("messenger_help_group_#{grp.to_s}".to_sym) << ":\n"
        cmds.each do |cmd|
            responce << "     " << cmd.to_s << ": " << l("messenger_help_command_#{cmd.command.to_s}_short".to_sym) << "\n"
        end
        responce << "\n"
      end
      
      responce << l(:messenger_help_footer_short)      
    end
        
    ::RedmineMessenger::Messenger.send_message(mid, responce)
  end
      
end