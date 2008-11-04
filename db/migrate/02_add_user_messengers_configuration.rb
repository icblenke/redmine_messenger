class AddUserMessengersConfiguration < ActiveRecord::Migration
  def self.up
    change_table :user_messengers do |t|
      t.boolean :resume_when_become_online, :default => true
      t.boolean :pause_when_become_offline_or_away, :default => true
      t.integer :issue_status_when_starting_timer_id, :null => true
      t.integer :issue_status_when_finishing_timer_id, :null => true
      t.integer :issue_status_when_finishing_timer_with_full_ratio_id, :null => true
      t.boolean :messenger_notifications_instead_of_emails, :default => false
      t.boolean :assigning_issue_when_starting_timer, :default => false
    end  
  end

  def self.down
    remove_column :user_messengers, :resume_when_become_online
    remove_column :user_messengers, :pause_when_become_offline_or_away
    remove_column :user_messengers, :issue_status_when_starting_timer_id
    remove_column :user_messengers, :issue_status_when_finishing_timer_id
    remove_column :user_messengers, :issue_status_when_finishing_timer_with_full_ratio_id
    remove_column :user_messengers, :messenger_notifications_instead_of_emails
    remove_column :user_messengers, :assigning_issue_when_starting_timer
  end
end
