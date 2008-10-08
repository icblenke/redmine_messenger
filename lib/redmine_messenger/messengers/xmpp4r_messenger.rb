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
          if m.type != :error
            receive_message("#{m.from.node}@#{m.from.domain}", m.body)
          else
            raise m.body
          end
        end
      end

      def send_message(to, body)
        @client.send(Jabber::Message.new(to, body).set_type(:chat))
      end

      #def destroy
      #  if @client
      #    @client.close
      #    @client = nil
      #  end
      #end

    end
  end
end