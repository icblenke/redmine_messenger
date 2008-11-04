module RedmineMessenger
  module Messengers
    class Xmpp4rMessenger < Messenger

      def initialize(config)
        super(config)
        
        jid = config['jid']
        jid += '/Redmine' unless jid =~ /\//
        
        @client = Jabber::Client.new(Jabber::JID.new(jid))
        @client.connect(config['host'],config['port'])
        @client.auth(config['password'])
        @client.send(Jabber::Presence.new(:chat, config['message']))
      
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

      def destroy
        if @client
          @rooster = nil
          @client.close
          @client = nil          
        end
      end

      private 
      
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