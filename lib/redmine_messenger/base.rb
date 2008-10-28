module RedmineMessenger
  class Base

    include GLoc
    
    class << self
      
      @instance = nil     
      
      def method_missing(method, *parameters)
        if /^deliver_([_a-z]\w*)/ =~ method.id2name
          message = instance.send($1, parameters)
          Messenger.send_message(message[0], message[1])
        elsif /^receive_([_a-z]\w*)/ =~ method.id2name
          messenger_id, message_body = parameters

          if user = UserMessenger.find_by_messenger_id(messenger_id)
            if user.verified?              
              if command = Base.commands[$1.to_sym]
                params = command.params_for_message(message_body)                
                unless params
                  base_instance.param_missing(messenger_id, $1)
                else
                  Messenger.send_message(messenger_id, instance.send(command.method, messenger_id, params))
                end
              else
                base_instance.help(messenger_id, message_body)
              end
            else 
              base_instance.verify(messenger_id, message_body)
            end
          else
            base_instance.verify(messenger_id, message_body)
          end          
        else
          super(method, parameters)
        end
      rescue => e
        "#{e.message}\n#{e.backtrace.join("\n")}"
      end

      def register_handler(command, options = {})
        cmd = Command.new(command, options)
        if block_given?
          yield(cmd)
        end
        Base.commands[cmd.command] = cmd
        Messenger.register_handler(instance.class, "receive_#{cmd.method.to_s}", cmd.options)        
      end
      
      def help_to_string(command = nil)
        return "HELP"
      end
      
      def commands
        @commands ||= {}
      end
      
      private
      
      def base_instance
        if @base_instance.nil?
          @base_instance = Base.new
        end
        @base_instance
      end    
      
      def instance
        if @instance.nil?
          @instance = new
        end
        @instance
      end      

    end

    def param_missing(messenger_id, command)
      Messenger.send_message(messenger_id, l(:messenger_error_param_missing, command))
    end
    
    def verify(messenger_id, code)
      if user = UserMessenger.find_by_messenger_id(messenger_id)
        if code =~ /^(\d+)/
          if user.verify($1)
            responce = l(:messenger_verify_user_verified)
          else
            responce = l(:messenger_verify_wrong_code)
          end
        else
          responce = l(:messenger_verify_not_verified)
        end
      else
        responce = l(:messenger_verify_user_not_registered)
      end
      Messenger.send_message(messenger_id, responce)
    end
      
    def help(messenger_id, body)
      body = body.gsub(/help/, "").strip
        
      if not body.blank? and command = Base.commands[body.to_sym]
        responce = l(:messenger_help_header_long, command.to_s) << "\n\n"
        responce << l("messenger_help_command_#{command.command.to_s}_long".to_sym)
        responce  << "\n\n" << l(:messenger_help_footer_long, command.to_s)
      else
        responce = l(:messenger_help_header_short) << "\n\n"

        groups = {}
      
        Base.commands.each_value do |cmd|
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
        
      Messenger.send_message(messenger_id, responce)
    end

  end
end