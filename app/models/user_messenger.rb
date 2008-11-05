class UserMessenger < ActiveRecord::Base

  validates_presence_of :messenger_id

  belongs_to :user
  belongs_to :issue
  belongs_to :issue_status_when_starting_timer, :class_name => "IssueStatus", :foreign_key => "issue_status_when_starting_timer_id"
  belongs_to :issue_status_when_finishing_timer, :class_name => "IssueStatus", :foreign_key => "issue_status_when_finishing_timer_id"
  belongs_to :issue_status_when_finishing_timer_with_full_ratio, :class_name => "IssueStatus", :foreign_key => "issue_status_when_finishing_timer_with_full_ratio_id"

  # Returns false if this user hasn't been verified yet -- that is, a verification code is not nil.
  def verified?
    verification_code.nil?
  end
  
  def language
    unless self.user.language.blank?
      self.user.language
    else
      Setting['default_language']
    end    
  end
  
  # Verify user. Returns true if user had been verified before or given code matches to verification code.
  def verify(code)
    return true unless self.verification_code
    return false unless self.verification_code == code    
    self.verification_code = nil
    self.save
  end

  def timer_add_note(note = nil)
    add_note_if_not_blank(note)
    self.save!
  end
  
  def timer_finish(done_ratio = nil, note = nil)
    add_note_if_not_blank(note)

    entry = TimeEntry.new
    entry.user = self.user
    entry.issue = self.issue
    entry.project = self.issue.project if self.issue.project_id
    entry.activity = Enumeration.find(:first, :conditions => {:opt => "ACTI"})
    entry.spent_on = Time.now.to_date
    entry.comments = self.timer_note unless self.timer_note.blank?
    entry.hours = timer_to_hours
    
    if done_ratio and done_ratio > 0
      done_ratio = 100 if done_ratio > 100
      self.issue.done_ratio = done_ratio
      
      if done_ratio == 100 and not self.issue_status_when_finishing_timer_with_full_ratio.nil?
        # set issue status when ratio = 100
        self.issue.status = self.issue_status_when_finishing_timer_with_full_ratio
      elsif done_ratio < 100 and not self.issue_status_when_finishing_timer.nil?
        # set issue status
        self.issue.status = self.issue_status_when_finishing_timer
      end

      return false unless self.issue.save
    end
    
    if entry.save
      timer_cancel
      true
    else
      false
    end   
  end  
  
  def timer_to_minutes
    self.timer_time + time_distance_in_minutes(self.timer_start_time)
  end
  
  def timer_to_hours
    Float(((Float(timer_to_minutes)/6).round))/10
  end 
  
  def timer_start(issue, note = nil)
    if self.assigning_issue_when_starting_timer? and issue.assigned_to != self.user
      # assing issue to current user
      issue.assigned_to = self.user
    end
    
    unless self.issue_status_when_starting_timer.nil?
      # set issue status
      issue.status = self.issue_status_when_starting_timer
    end
    
    if issue.changed?
      return false unless issue.save
    end
    
    add_note_if_not_blank(note)    
    self.timer_paused_because_of_status_change = false
    self.timer_time = 0
    self.timer_start_time = Time.now
    self.issue = issue
    self.save!
  end
  
  def timer_resume(note = nil)
    add_note_if_not_blank(note)    
    self.timer_paused_because_of_status_change = false
    self.timer_start_time = Time.now
    self.save!
  end
  
  def timer_pause(note = nil, because_of_status = false)
    add_note_if_not_blank(note)    
    self.timer_paused_because_of_status_change = because_of_status
    self.timer_time ||= 0
    self.timer_time += time_distance_in_minutes(self.timer_start_time)
    self.timer_start_time = nil
    self.save!
  end
  
  def timer_cancel
    self.timer_paused_because_of_status_change = false
    self.timer_note = nil
    self.timer_start_time = nil
    self.timer_time = nil
    self.issue = nil
    self.save!
  end
  
  def timer_running?
    not self.issue_id.nil?
  end
  
  def timer_paused?
    self.timer_start_time.nil? and not self.issue.nil?
  end
  
  protected
 
  # Set new verification code if messenger_id has been changed.
  def before_save
    if self.messenger_id_changed?
      self.verification_code = rand(999999).to_s.center(6, rand(5).to_s)
      RedmineMessenger::Messenger.send_message(self.messenger_id, ll(language, :messenger_welcome_message))
    end
    true
  end  
  
  private 
  
  def time_distance_in_minutes(time)
    if time
      Integer((Time.now - time)/60)
    else
      0
    end
  end
  
  def add_note_if_not_blank(note)
    unless note.blank?
      self.timer_note ||= ""
      self.timer_note << note << "\n"
    end
  end
  
end