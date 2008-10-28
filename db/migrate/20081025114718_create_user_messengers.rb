class CreateUserMessengers < ActiveRecord::Migration
  def self.up
    create_table :user_messengers do |t|
      t.references :user
      t.references :issue, :null => true
      t.string :messenger_id, :verification_code
      t.integer :timer_time, :null => true
      t.datetime :timer_start_time, :null => true
      t.string :timer_note, :null => true, :limit => 255      
    end
  end

  def self.down
    drop_table :user_messengers
  end
end
