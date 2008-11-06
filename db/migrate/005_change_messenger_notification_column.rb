class ChangeMessengerNotificationColumn < ActiveRecord::Migration
  def self.up
    change_column :user_messengers, :messenger_notifications, :boolean, :default => true
  end

  def self.down   
    change_column :user_messengers, :messenger_notifications, :string, :default => "mail"
  end
end
