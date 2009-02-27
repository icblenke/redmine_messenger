require 'redmine'

require 'rubygems'
require 'yaml'
require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'

unless defined? I18n
  I18n = GLoc
end

require_dependency 'redmine_messenger/messenger'
require_dependency 'redmine_messenger/messengers/mock_messenger'
require_dependency 'redmine_messenger/messengers/xmpp4r_messenger'
require_dependency 'redmine_messenger/base'
require_dependency 'redmine_messenger/command'
require_dependency 'app/models/mailer'
require_dependency 'redmine_messenger/mailer'

Dir[File.join(File.dirname(__FILE__), "app/messengers/*.rb")].each do |file|
  require_dependency file
end

Redmine::Plugin.register :redmine_messenger do
  name 'Messenger'
  author 'Maciej Szczytowski'
  description 'Messenger is a plugin to allow users to communicate with Redmine via Instant Messenger.'
  version '0.0.7'
  
  permission :user_messenger, {"user_messenger".to_sym => [:index]}, :public => true
  
  menu :account_menu, :user_messenger, { :controller => 'user_messenger', :action => 'index' }, :caption => :messenger_menu_label, :after => :my_account, :if => Proc.new { User.current.logged? }
end
