class AddPauseBecauseOfStatusChange < ActiveRecord::Migration
  def self.up
    change_table :user_messengers do |t|
      t.boolean :timer_paused_because_of_status_change, :default => false
    end  
  end

  def self.down
    remove_column :user_messengers, :timer_paused_because_of_status_change
  end
end
