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
          mid, body = parameters
          if user = UserMessenger.find_by_messenger_id(mid)
            if user.verified?
              if command = Base.commands[$1.to_sym]
                params = command.send(:receive, user, body)
                unless params
                  base_instance.param_missing(mid, $1)
                else
                  Messenger.send_message(mid, instance.send(command.method, params[0], params[1]))
                end
              else
                base_instance.help(mid, body)
              end
            else 
              base_instance.verify(mid, body)
            end
          else
            base_instance.verify(mid, body)
          end          
        else
          super(method, parameters)
        end
      rescue => e
        "#{e.message}\n#{e.backtrace.join("\n")}"
      end

      def register_message_listener(command, options = {})
        cmd = Command.new(command, options)
        if block_given?
          yield(cmd)
        end
        Base.commands[cmd.command] = cmd
        Messenger.add_message_handler(instance.class, "receive_#{cmd.method.to_s}", cmd.options)        
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

    def param_missing(mid, command)
      Messenger.send_message(mid, l(:messenger_error_param_missing, command))
    end
    
    def verify(mid, code)
      if user = UserMessenger.find_by_messenger_id(mid)
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
      Messenger.send_message(mid, responce)
    end
      
    def help(mid, body)
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
        
      Messenger.send_message(mid, responce)
    end

  end
end