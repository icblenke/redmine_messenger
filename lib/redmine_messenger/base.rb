module RedmineMessenger
  class Base

    if defined?(Redmine::I18n)
      include Redmine::I18n
    else
      extend MessengerI18nPatch
    end
   
    class << self
     
      # Catch all methods starting with <tt>delivel_</tt> or <tt>receive_</tt>.
      #
      # Methods <tt>delivel_METHOD_NAME</tt> sends +parameters+ to your 
      # method METHOD_NAME which must return array with messenger_id (first 
      # element) and message_body (second parameter). This message is send to 
      # given user. If your method return false, message won't be sent.
      #
      # Methods <tt>delivel_COMMAND_NAME</tt> are call by messenger (see <tt>Messenger.receive_message</tt>). 
      # As results one of this action is possible:
      # * message that user is not registered
      # * user is verified
      # * message that command param is missing
      # * call is proxied to registered handler (if exists)
      # * message with help is sent.
      def method_missing(method, *parameters)
        if /^deliver_([_a-z]\w*)/ =~ method.id2name
          message = instance.send($1, parameters)          
          Messenger.send_message(message[0], message[1]) if message
        elsif /^status_([_a-z]\w*)/ =~ method.id2name
          messenger_id, new_status = parameters
          
          if messenger = UserMessenger.find_by_messenger_id(messenger_id) and messenger.verified?     
            responce = instance.send($1.to_sym, messenger, new_status)                        
            Messenger.send_message(messenger_id, responce) if responce
          end          
        elsif /^receive_([_a-z]\w*)/ =~ method.id2name
          messenger_id, message_body = parameters

          if messenger = UserMessenger.find_by_messenger_id(messenger_id)
            if messenger.verified?              
              if command = Base.commands[$1.to_sym]
                params = command.params_for_message(message_body)
                unless params
                  # Param is missing.
                  base_instance.param_missing(messenger, $1)
                else
                  # Calling handler.
                  responce = instance.send(command.method, messenger, params)
                  Messenger.send_message(messenger_id, responce) if responce
                end
              else
                # Command not found, show help.
                base_instance.help(messenger, message_body)
              end
            else 
              # User not verify.
              base_instance.verify(messenger_id, message_body)
            end
          else
            # User not registered.
            base_instance.verify(messenger_id, message_body)
          end          
        else
          super(method, parameters)
        end
      rescue => e
        Messenger.logger.error "RedmineMessenger: exception catched '#{e.message}':\n" + e.backtrace.join("\n")
      end

      # Register message handler (see <tt>Command</tt>).
      def register_handler(command, options = {})
        cmd = Command.new(command, options)
        yield(cmd) if block_given?
        Base.commands[cmd.command] = cmd
        Messenger.register_message_handler(instance.class, "receive_#{cmd.method.to_s}", cmd.options)
      end
      
      # Register status handler.
      def register_status_handler(command, status = :all)
        Messenger.register_status_handler(instance.class, "status_#{command.to_s}", status)
      end
      
      # Returns help for given command or all help if command doesn't exists.
      def help_to_string(messenger, message_body_with_command = nil)
        # Remove help token if exists.        
	if message_body_with_command == "help"
            # Help for all commands.
            help = ll(messenger.language, :messenger_help_header_short) << "\n\n"

            groups = {}

            Base.commands.each_value do |cmd|
              groups[cmd.group] ||= []
              groups[cmd.group] << cmd
            end

            groups.each do |grp, cmds|
              help << ll(messenger.language, "messenger_help_group_#{grp.to_s}".to_sym) << ":\n"
              cmds.each do |cmd|
                help << "     " << cmd.to_s << ": " << ll(messenger.language, "messenger_help_command_#{cmd.command.to_s}_short".to_sym) << "\n"
              end
              help << "\n"
            end

            help << ll(messenger.language, :messenger_help_footer_short)
        end
        
	help
      end

      # Registered commands.
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

    # Send 'param missing' message.
    def param_missing(messenger, command)
      Messenger.send_message(messenger.messenger_id, Base.ll(messenger.language, :messenger_error_param_missing, :command => command))
    end
    
    # Verify user and send proper message.
    def verify(messenger_id, code)     
      if user = UserMessenger.find_by_messenger_id(messenger_id)
        if code =~ /^(\d+)/
          if user.verify($1)
            responce = Base.ll(Setting['default_language'], :messenger_verify_user_verified)
          else
            responce = Base.ll(Setting['default_language'], :messenger_verify_wrong_code)
          end
        else
          responce = Base.ll(Setting['default_language'], :messenger_verify_not_verified)
        end
      else
        responce = Base.ll(Setting['default_language'], :messenger_verify_user_not_registered)
      end
      Messenger.send_message(messenger_id, responce)
    end
      
    # Send help message.
    def help(messenger, message_body)      
      help = Base.help_to_string(messenger, message_body)
      Messenger.send_message(messenger.messenger_id, help)
    end

  end
end
