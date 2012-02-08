module RedmineMessenger
  class Messenger

    attr_reader :config
    
    # Registers message handler. Handlers are invoke when messenger receive message (see <tt>receive_message</tt> and <tt>Command</tt>).
    def register_message_handler(object, method, options)      
      @message_handlers << [object, method, @message_default_options.merge(options)]
    end
    
    # Registers status handler. Handlers are invoke when user change his status.
    def register_status_handler(object, method, status)      
      @status_handlers << [object, method, status]
    end
    
    # Sends message with +body+ to the user +messenger_id+. Method is redefined in subclasses.
    def send_message(messenger_id, body)
      # redefine it
    end

    protected

    def initialize(config)
      @config = config
      @message_default_options = { :pattern => nil }     
      @message_handlers = []
      @status_handlers = []
    end
    
    # Receives message from +messenger_id+ with +body+ and resends it to registered handlers (see <tt>register_handler</tt>).
    # Method is called by messenger implementations.
    def receive_message(messenger_id, body)
      received = false
      @message_handlers.each do |object, method, options|
        if options[:pattern].nil? or options[:pattern] =~ body 
          received = true
          object.send(method, messenger_id, body)
        end        
      end      
      unless received        
        # TODO It's not safe. Command can have name 'command_not_registered'.
        RedmineMessenger::Base.receive_command_not_registered(messenger_id, body)
      end
    end
    
    def receive_status(messenger_id, new_status)
      @status_handlers.each do |object, method, status|
        if status == :all or status == new_status
          object.send(method, messenger_id, new_status)
        end
      end
    end
    
    class << self

      @instance = nil
      @logger = nil

      # Proxy. Sends given method to instance of messenger (see <tt>create_messenger</tt>).
      def method_missing(method, *params, &block)
        unless @instance
          @instance = create_messenger
        end
        @instance.send(method, *params, &block)
      end

      def logger
        unless @logger
          logfile = "log/redmine_messenger.log"
          Rails.logger.info "RedmineMessenger: opening log file " + logfile
          @logger = Logger.new(logfile)
          @logger.info "Log file opened"
        end
        @logger
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
          RedmineMessenger::Messengers.const_get(messenger_name).new(config,self.logger)
        else
          raise "Messenger not found: #{config['type']}"
        end
      end
      
    end
    
  end
end
