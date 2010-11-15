module RedmineMessenger
  module Messengers
    class Xmpp4rMessenger < Messenger

      def initialize(config, logger)
        super(config)
        
        @logger = logger

        jid = config['jid']
        jid += "/Redmine#{rand(100000)}" unless jid =~ /\//

        @client = Jabber::Client.new(Jabber::JID.new(jid))
        
        @client.use_ssl = config['ssl'] || false
        @client.allow_tls = config['allow_tls'] || false

        Jabber::debug = true if config['debug']
        Jabber::logger = @logger

        connect

        @client.on_exception do |e,client,where|
          @logger.fatal "RedmineMessenger: exception catched '#{e.message}' (#{where.to_s}):\n" + e.backtrace.join("\n") + "\ntrying to reconnect ..."
          sleep 5
          reconnect
        end
        
        @client.add_message_callback do |m|
          unless m.type == :error
            begin 
              @logger.debug "RedmineMessenger: receiving message from #{m.from.node}@#{m.from.domain}"
              receive_message("#{m.from.node}@#{m.from.domain}", m.body)
            rescue => e
              @logger.error "RedmineMessenger: exception catched while receiving message '#{e.message}':\n" + e.backtrace.join("\n")
            end
          else
            @logger.error "RedmineMessenger: error received '#{m.body}'"
          end
        end
      
        @roster = Jabber::Roster::Helper.new(@client)

        @roster.add_presence_callback do |item,oldpres,pres|
          pres ||= Jabber::Presence.new
          oldpres ||= Jabber::Presence.new
          
          old_status = status(oldpres.priority, oldpres.type, oldpres.show)
          new_status = status(pres.priority, pres.type, pres.show)
            
          unless old_status == new_status
            begin
              @logger.debug "RedmineMessenger: receiving status from #{item.jid.node}@#{item.jid.domain}"
              receive_status("#{item.jid.node}@#{item.jid.domain}", new_status)
            rescue => e
              @logger.error "RedmineMessenger: exception catched while receiving status '#{e.message}'\n" + e.backtrace.join("\n")
            end
          end
        end

        @roster.add_subscription_callback do |item,pres|
          begin
            @logger.debug "RedmineMessenger: receiving #{pres.type} from #{pres.from}"
          rescue => e
            @logger.error "RedmineMessenger: exception catched while processing subscription '#{e.message}'\n" + e.backtrace.join("\n")
          end
        end

        @roster.add_subscription_request_callback do |item,pres|
          @logger.debug "RedmineMessenger: receiving subscription request from #{pres.from}, accepting it"
          @roster.accept_subscription(pres.from)
        end
      end

      def send_message(to, body)
        @logger.debug "RedmineMessenger: sending message to #{to}"
        @client.send(Jabber::Message.new(to, body).set_type(:chat))
      end

      private 

      def reconnect
        if @client.is_connected?
          @logger.info "RedmineMessenger: disconnecting ..."
          @client.close          
        end        
        connect        
      end
      
      def connect
        unless @client.is_connected?
          @logger.info "RedmineMessenger: connecting ..."
          @client.connect(config['host'],config['port'])
          @client.auth(config['password'])
          @client.send(Jabber::Presence.new(:chat, config['message']))
        end
      end
      
      def status(priority, type, show)
        if priority.nil? or type == :unavailable or show == :away or show == :xa
          :unavailable
        else
          :available          
        end          
      end
      
    end
  end
end
