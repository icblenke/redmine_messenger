class CreateUserMessengers < ActiveRecord::Migration
  def self.up
    create_table :user_messengers do |t|
      t.references :user
      t.string :messenger_id, :verification_code
    end
  end

  def self.down
    drop_table :user_messengers
  end
end
