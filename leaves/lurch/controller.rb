
require 'slimtimer4r'

class Controller < Autumn::Leaf
  @@TASKS=[]
  @@INTERRUPTIONS=[]
  
  def start_command(stem, sender, reply_to, msg)
    #@timer.create_timeentry(DateTime.now, )
  end
  
  def task_command(stem, sender, reply_to, msg)
    init_slim_timer
    task = Timing::Task.new(:user => sender, :description => msg)
    var :msg => msg
    @@TASKS << task
    # @args = msg.split(",")
    # var :name => (@args[0] ||= 'Testing')
    #     var :tags => (@args[1].split("/"))
    #     var :coworker_emails => (@args[2].split("/"))
    #     var :reporter_emails => (@args[3].split("/"))
    #     var :completed_on => (@args[4] ||= nil)
    #@timer.create_task(:name, :tags, :coworker_emails, :reporter_emails, :completed_on)
  end
  
  def interrupt_command(stem, sender, reply_to, msg)
    @@TASKS.each do |t|
      tasks = []
      if t.user == sender
        t.end! "Interrupted! '#{msg}'"
        tasks << t
        rupt = Timing::Interruption.new(:user => sender, :description => msg)

        @@INTERRUPTIONS << rupt
      end
      var :tasks => tasks
      var :msg => msg
    end
  end
  
  def resume_command(stem, sender, reply_to, msg)
    @@INTERRUPTIONS.each do |i|
      if i.user == sender
        i.end! "RESUMING TASK (#{msg})"
        var :msg => msg
        @@TASKS.each do |t|
          t.resume! "#{msg}"
        end
      end
    end
  end
  
  def about_command(stem, sender, reply_to, msg)
    'Lurch is a time-keeping bot (Autumn Leaf) developed by Mark Coates & Noah Sussman at ZepFrog Corp. http://zepfrog.com/development'
  end
  
  private
  API_KEY = 'eacb7258085b816a1ea0fadcade69e'
  def init_slim_timer
    @timer = SlimTimer.new('mcoates@zepinvest.com', 'whoami23', API_KEY)
  end
  
end


module Timing
  class Task < Object
    attr_accessor :user, :description
    def initialize(args={})
      @started_at = Time.now
      @user = args[:user]
      @description = args[:description]
      @tags = args[:tags]
      @coworker_emails = args[:coworker_emails] || nil
      @reporter_emails = args[:reporter_emails] || nil
      @ended_at = nil
      @total_time = 0
    end
    
    def end!(reason)
      @ended_at = Time.now
      @total_time += time_elapsed
    end
    def current_time
      Time.now
    end
    def time_elapsed
      (current_time - @started_at) if @ended_at.nil? else (@ended_at - @started_at)
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
      @started_at = Time.now
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