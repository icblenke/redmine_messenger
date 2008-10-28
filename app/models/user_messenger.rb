class UserMessenger < ActiveRecord::Base

  validates_presence_of :messenger_id

  belongs_to :user

  # Returns false if this user hasn't been verified yet -- that is, a verification code is not nil.
  def verified?
    verification_code.nil?
  end
  
  # Verify user. Returns true if user had been verified before or given code matches to verification code.
  def verify(code)
    return true unless self.verification_code
    return false unless self.verification_code == code    
    self.verification_code = nil
    self.save
  end

  protected

  # Set new verification code if messenger_id has been changed.
  def before_save
    self.verification_code = rand(999999).to_s.center(6, rand(5).to_s) if self.messenger_id_changed?
    true
  end  
  
end