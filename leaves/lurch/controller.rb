require 'slimtimer4r'

class Controller < Autumn::Leaf
  @@TASKS=[]
  @@INTERRUPTIONS=[]
  
  def task_command(stem, sender, reply_to, msg)
    #init_slim_timer
    task = Timing::Task.new(:user => sender, :description => msg)
    var :msg => msg
    var :id => task.id
    @@TASKS << task
  end
  
  def tasks_command(stem, sender, reply_to, msg)
    @@TASKS.each do |t|
      if t.user == sender
        stem.message "<ID:#{t.id}> '#{t.description}' (#{t.total_time == 0 ? t.time_elapsed : t.total_time + t.time_elapsed} seconds) #{('| Tagged: ' + t.tags.join(", ") + '.') unless t.tags.nil? || t.tags.empty?}"
      end
    end    
  end
  
  def interrupt_command(stem, sender, reply_to, msg)
    tasks = []
    @@TASKS.each do |t|
      if t.user == sender
        t.pause! "Interrupted! '#{msg}'"
        rupt = Timing::Interruption.new(:user => sender, :description => msg)
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
      records << i      
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
    rescue StandardError => bang
      var :exception => "An error occurred: (#{bang})"
    end
  end
  
  def gist_command(stem, sender, reply_to, msg)
    # hmmm...
  end
  
  def tag_command(stem, sender, reply_to, msg)
    if msg.nil?
      render :tag_help
    else
      args = msg.split(" ")
      id   = args[0].to_i
      tags = args[1].split(',')
      records = @@TASKS + @@INTERRUPTIONS
      records.each do |t|
        if t.id == id
          stem.message "Found object <#{id}>:"
          tags.each do |tag|
            t.tag! tag
          end
        end
      end
      var :tags => tags.join(',')
    end
  end
  
  # Look up acronyms and man pages. (@nsussman)
  def wtf_command(stem, sender, reply_to, msg)
    %x{wtf #{msg}}
  end
  
  def about_command(stem, sender, reply_to, msg)
    "#{options[:about_msg]}"
  end
  
  private
  
  def init_slim_timer
    @timer = SlimTimer.new(options[:st_user], options[:st_password], options[:st_api_key])
  end
  
  def synchronize_with_server(records)
    init_slim_timer
    task = nil
    records.each do |r|
      task = @timer.create_task r.description, r.tags
      @timer.create_timeentry r.created_at, r.total_time, task['id'], r.ended_at
    end
  end
  
  def speed_bump(&block)
    sleep(1)
    yield
    sleep(1)
  end
  
end


module Timing
  class Task < Object
    attr_accessor :user, :description, :total_time, :created_at, :ended_at, :started_at, :paused_at, :pause_time, :tags
    def initialize(args={})
      @created_at = Time.new
      @started_at = Time.new
      @user = args[:user]
      @description = args[:description]
      @tags = args[:tags]
      @coworker_emails = args[:coworker_emails] || nil
      @reporter_emails = args[:reporter_emails] || nil
      @ended_at = nil
      @paused_at = nil
      @total_time = 0
      @pause_time = 0
      @tags = []
    end
    
    def pause!(reason)
      @total_time += (Time.new - @started_at)
      @paused_at = Time.new
    end
    
    def paused?
      false if @paused_at.nil? else true
    end
    
    def end!(reason)
      @ended_at = Time.new
      @total_time += @ended_at - @started_at
    end
    
    def resume!(msg)
      @pause_time += Time.new - @paused_at
      @paused_at = nil
      @started_at = Time.new
      @ended_at = nil
    end
    
    def tag!(tag)
      @tags << tag
    end
    
    def current_time
      Time.new
    end
    
    def time_elapsed
      if @ended_at.nil?
        if @paused_at.nil?
          current_time - @started_at 
        else
          @paused_at - @started_at
        end
      else 
        @ended_at - @started_at
      end
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
  end
  class Interruption < Task
    def inititalize(args={})
      super
      @tags << 'interruption'
    end
    def tags
      @tags.include?('interruption') ? @tags : @tags << 'interruption'
    end
  end
end