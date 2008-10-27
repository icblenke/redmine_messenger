module RedmineMessenger
  class Messenger

    attr_reader :config
      
    def initialize(config)
      @config = config
      @default_options = { :pattern => nil, :default => false }     
      @handlers = []
    end

    def add_message_handler(object, method, options)      
      @handlers << [object, method, @default_options.merge(options)]
    end

    def receive_message(from, body)
      received = false
      @handlers.each do |object, method, options|
        if (not options[:default] and not options[:pattern]) or (options[:default] and not received) or (options[:pattern] and options[:pattern] =~ body)
          object.send(method, from, body) and received = true          
        end        
      end      
      unless received        
        RedmineMessenger::Base.receive_command_not_registered(from, body)
      end
    end
    
    def send_message(to, body)
      # defined in subclasses
    end
    
    class << self

      @instance = nil

      def method_missing(method, *params, &block)
        unless @instance
          @instance = create_messenger
        end
        @instance.send(method, *params, &block)
      end
      
      private

      def load_config(config_file = "#{RAILS_ROOT}/config/messenger.yml")
        unless File.exists?(config_file)
          raise "Config not found: #{config_file}"
        end
        YAML.load_file(config_file)[RAILS_ENV]
      end

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