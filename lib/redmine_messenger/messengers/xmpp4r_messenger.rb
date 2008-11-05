module RedmineMessenger
  module Messengers
    class Xmpp4rMessenger < Messenger

      def initialize(config)
        super(config)
        
        jid = config['jid']
        jid += '/Redmine' unless jid =~ /\//

        @client = Jabber::Client.new(Jabber::JID.new(jid))
        
        RAILS_DEFAULT_LOGGER.info "CONNECTING"
        
        connect

        @client.on_exception do |e,client,where|
          RAILS_DEFAULT_LOGGER.fatal "RedmineMessenger: exception catched '#{e.message}' (#{where.to_s}; trying to reconnect ..."
          sleep 5
          reconnect
        end
        
        @client.add_message_callback do |m|
          unless m.type == :error
            receive_message("#{m.from.node}@#{m.from.domain}", m.body)
          else
            raise m.body
          end
        end
      
        @roster = Jabber::Roster::Helper.new(@client)

        @roster.add_presence_callback do |item,oldpres,pres|
          pres ||= Jabber::Presence.new
          oldpres ||= Jabber::Presence.new
          
          old_status = status(oldpres.priority, oldpres.type, oldpres.show)
          new_status = status(pres.priority, pres.type, pres.show)
            
          unless old_status == new_status
            receive_status("#{item.jid.node}@#{item.jid.domain}", new_status)
          end
        end
      end

      def send_message(to, body)
        @client.send(Jabber::Message.new(to, body).set_type(:chat))
      end

      private 

      def reconnect
        if @client.is_connected?
          RAILS_DEFAULT_LOGGER.info "RedmineMessenger: disconnecting"
          @client.close          
        end        
        connect        
      end
      
      def connect
        unless @client.is_connected?
          RAILS_DEFAULT_LOGGER.info "RedmineMessenger: connecting"
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