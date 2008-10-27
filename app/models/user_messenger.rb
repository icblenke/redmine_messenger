class UserMessenger < ActiveRecord::Base

  validates_presence_of :messenger_id

  belongs_to :user

  def verified?
    verification_code.nil?
  end
  
  def self.user_by_messenger_id(mid)
    user_messenger = UserMessenger.find_by_messenger_id(mid)
    
    return nil unless user_messenger
    return nil unless user_messenger.verified?

    user_messenger.user    
  end
  
  def verify(code)
    return true unless self.verification_code
    return false unless self.verification_code == code    
    self.verification_code = nil
    self.save
  end

  protected

  def before_save
    self.verification_code = rand(999999).to_s.center(6, rand(5).to_s) if self.messenger_id_changed?
    true
  end  
  
end