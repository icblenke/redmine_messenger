require 'redmine'

require 'rubygems'
require 'yaml'
require 'xmpp4r'

require_dependency 'redmine_messenger/messenger'
require_dependency 'redmine_messenger/messengers/mock_messenger'
require_dependency 'redmine_messenger/messengers/xmpp4r_messenger'
require_dependency 'redmine_messenger/base'

require File.join(File.dirname(__FILE__), 'app/model/messenger_receiver.rb')

Redmine::Plugin.register :messenger do
  name 'Messenger'
  author 'Maciej Szczytowski'
  description 'Messenger is a plugin to allow users to communicate with Redmine via XMPP protocol.'
  version '0.0.1'
end