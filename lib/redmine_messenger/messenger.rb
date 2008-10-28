module RedmineMessenger
  class Messenger

    attr_reader :config
    
    # Registers message handler. Handlers are invoke when messenger receive message (see <tt>receive_message</tt> and <tt>Command</tt>).
    def register_handler(object, method, options)      
      @handlers << [object, method, @default_options.merge(options)]
    end
    
    # Sends message with +body+ to the user +messenger_id+. Method is redefined in subclasses.
    def send_message(messenger_id, body)
      # redefine it
    end

    protected

    def initialize(config)
      @config = config
      @default_options = { :pattern => nil }     
      @handlers = []
    end
    
    # Receives message from +messenger_id+ with +body+ and resends it to registered handlers (see <tt>register_handler</tt>).
    # Method is called by messenger implementations.
    def receive_message(messenger_id, body)
      received = false
      @handlers.each do |object, method, options|
        if options[:pattern].nil? or options[:pattern] =~ body 
          received = true
          object.send(method, messenger_id, body)
        end        
      end      
      unless received        
        RedmineMessenger::Base.receive_command_not_registered(messenger_id, body)
      end
    end

    
    class << self

      @instance = nil

      # Proxy. Sends given method to instance of messenger (see <tt>create_messenger</tt>).
      def method_missing(method, *params, &block)
        unless @instance
          @instance = create_messenger
        end
        @instance.send(method, *params, &block)
      end
      
      private

      # Reads the configuration from config/messenger.yml.
      def load_config(config_file = "#{RAILS_ROOT}/config/messenger.yml")
        unless File.exists?(config_file)
          raise "Config not found: #{config_file}"
        end
        YAML.load_file(config_file)[RAILS_ENV]
      end

      # Creates messenger for given configuration (see <tt>load_config</tt>).
      def create_messenger
        config = load_config
        messenger_name = "#{config['type'].camelize}Messenger"
        if RedmineMessenger::Messengers.const_defined?(messenger_name)
          RedmineMessenger::Messengers.const_get(messenger_name).new(config)
        else
          raise "Messenger not found: #{config['type']}"
        end
      end
      
    end
    
  end
end