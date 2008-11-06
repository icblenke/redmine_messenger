class AddMessengerNotificationColumn < ActiveRecord::Migration
  def self.up
    remove_column :user_messengers, :messenger_notifications_instead_of_emails
    add_column :user_messengers, :messenger_notifications, :string, :default => "mail"
  end

  def self.down   
    add_column :user_messengers, :messenger_notifications_instead_of_emails, :boolean, :default => false
    remove_column :user_messengers, :messenger_notifications
  end
end
