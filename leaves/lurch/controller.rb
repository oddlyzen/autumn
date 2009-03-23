
require 'slimtimer4r'

class Controller < Autumn::Leaf
  @@TASKS=[]
  @@INTERRUPTIONS=[]
  
  def start_command(stem, sender, reply_to, msg)
    #@timer.create_timeentry(DateTime.now, )
  end
  
  def task_command(stem, sender, reply_to, msg)
    #init_slim_timer
    task = Timing::Task.new(:user => sender, :description => msg)
    var :msg => msg
    @@TASKS << task
  end
  
  def interrupt_command(stem, sender, reply_to, msg)
    tasks = []
    @@TASKS.each do |t|
      if t.user == sender
        t.end! "Interrupted! '#{msg}'"
        rupt = Timing::Interruption.new(:user => sender, :description => msg)\
      end
      tasks << t
      @@INTERRUPTIONS << rupt
    end
    var :tasks => tasks
    var :msg => msg
  end
  
  def resume_command(stem, sender, reply_to, msg)
    @@INTERRUPTIONS.each do |i|
      if i.user == sender
        i.end! "RESUMING TASK (#{msg})"
      end
    end
    tasks = []
    @@TASKS.each do |t|
      t.resume! "#{msg}"
      tasks << t
    end
    var :tasks => tasks
    var :msg => msg
  end
  
  def end_command(stem, sender, reply_to, msg)
    records = []
    @@INTERRUPTIONS.each do |i|
      if i.user == sender
        records << i
        i.end! "#{msg}"
      end
      @@INTERRUPTIONS.delete i
    end
    @@TASKS.each do |t|
      if t.user == sender
        records << t
        t.end! "#{msg}"
      end
      @@TASKS.delete t
    end
    var :records => records
    begin
      synchronize_with_server(records)
    rescue
      var :exception => "An error occurred."
    end
  end
  
  def gist_command(stem, sender, reply_to, msg)
    # hmmm...
  end
  
  def tag_command(stem, sender, reply_to, msg)
    tags = msg.split(',')
    @@TASKS.each do |t|
      if t.user == sender
        tags.each do |tag|
          t.tag! tag
        end
      end
    end
    var :tags => tags.join(',')
  end
  
  def about_command(stem, sender, reply_to, msg)
    'Lurch is a time-keeping bot (Autumn Leaf) developed by Mark Coates & Noah Sussman at ZepFrog Corp. http://zepfrog.com/development'
  end
  
  private
  
  def init_slim_timer
    @timer = SlimTimer.new(options[:st_user], options[:st_password], options[:st_api_key])
  end
  def synchronize_with_server(records)
    init_slim_timer
    task = nil
    records.each do |r|
      task = @timer.create_task r.description, t.tags
      sleep(1)
      @timer.create_timeentry r.started_at, r.time_elapsed, task['id'], r.ended_at, r.tags
      sleep(1)
    end
  end
  
end


module Timing
  class Task < Object
    attr_accessor :user, :description, :total_time, :ended_at, :started_at, :tags
    def initialize(args={})
      @started_at = Time.new
      @user = args[:user]
      @description = args[:description]
      @tags = args[:tags]
      @coworker_emails = args[:coworker_emails] || nil
      @reporter_emails = args[:reporter_emails] || nil
      @ended_at = nil
      @total_time = 0
      @tags = []
    end
    
    def end!(reason)
      @ended_at = Time.new
      if @total_time
        @total_time += time_elapsed
      end
      @total_time ||= time_elapsed
    end
    
    def tag!(tag)
      @tags << tag
    end
    
    def current_time
      Time.new
    end
    
    def time_elapsed
      if @ended_at.nil?
        current_time - @started_at 
      else 
        @ended_at - @started_at
      end
    end
    
    def tags
      @tags || nil
    end
    
    def tags=(array)
      @tags = array
    end
    
    def coworker_emails
      @coworker_emails || []
    end
    
    def reporter_emails
      @reporter_emails || []
    end
    
    def coworker_emails=(array)
      @coworker_emails = array
    end
    
    def reporter_emails=(array)
      @reporter_emails = array
    end
    
    def resume!(msg)
      @started_at = Time.new
      @ended_at = nil
    end
  end
  class Interruption < Task
    def initialize(args={})
      @started_at = Time.now
      @user = args[:user]
      @description = args[:description]
      @tags = args[:tags]
      @coworker_emails = args[:coworker_emails] || nil
      @reporter_emails = args[:reporter_emails] || nil
      @ended_at = nil
      @total_time = nil
    end
  end
end