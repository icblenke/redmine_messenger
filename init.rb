require 'redmine'

Redmine::Plugin.register :redmine_jabber do
  name 'Redmine Messenger plugin'
  author 'Maciej Szczytowski'
  description 'This is a plugin for Redmine'
  version '0.0.1'
end

require_dependency 'redmine_messenger/messenger_holder'
require_dependency 'redmine_messenger/messenger'
require_dependency 'redmine_messenger/messengers/mock_messenger'
require_dependency 'redmine_messenger/messengers/xmpp4r_messenger'
require_dependency 'redmine_messenger/base'

require File.join(File.dirname(__FILE__), 'app/messengers/test_jabber_messenger.rb')