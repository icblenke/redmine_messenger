module RedmineMessenger
  class Base

    class << self
      
      @instance = nil
      
      def method_missing(method, *parameters)
        if /^deliver_([_a-z]\w*)/ =~ method.id2name
          message = instance.send($1, parameters)
          Messenger.send_message(message[0], message[1])
        else
          super(method, parameters)
        end
      end

      def receives_messages(method, options = {})
        Messenger.add_message_handler(instance, method, options)
      end

      private
  
      def instance
        if @instance.nil?
          @instance = new
        end
        @instance
      end

    end

  end
end