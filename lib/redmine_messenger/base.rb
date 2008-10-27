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
                if(params.is_a? String)
                  responce = params
                else
                  responce = instance.send(command.method, params[0], params[1])
                end
                Messenger.send_message(mid, responce)
              else
                base_messenger_instance.help(mid, body)
              end
            end              
          else
            base_messenger_instance.verify(mid, body)
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
      
      def base_messenger_instance
        if @base_messenger.nil?
          @base_messenger = BaseMessenger.new
        end
        @base_messenger
      end
      
      def instance
        if @instance.nil?
          @instance = new
        end
        @instance
      end      

    end

  end
end