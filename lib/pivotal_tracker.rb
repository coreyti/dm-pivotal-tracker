require "rubygems"
require 'optparse'
require 'ostruct'
require 'datamapper'

dir = File.join(File.dirname(__FILE__), 'pivotal_tracker')
Dir["#{dir}/**/*.rb"].each do |file|
  require file
end

module PivotalTracker
  def self.read(args)
    options = parse_args(args)

    DataMapper.setup(:pivotal, {
      :adapter => 'pivotal',
      :token   => options[:token],
      :server  => 'http://www.pivotaltracker.com/services/v1'
    })

    project = PivotalTracker::Project.get(options[:project_id])
    if(options[:story_id])
      puts "story:   #{project.stories.first(:id => options[:story_id])}"
    else
      puts "project: #{project.inspect}"
    end
  end

  def self.parse_args(args)
    options = load_options_from_config

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: pivotal_tracker [options]"

      opts.on("-p", "--project PROJECT_ID", Integer, "Specify the project id") do |project_id|
        options[:project_id] = project_id
      end

      opts.on("-s", "--story STORY_ID", Integer, "Specify the story id") do |story_id|
        options[:story_id] = story_id
      end

      opts.on("-t", "--token TOKEN", "Specify the API token") do |token|
        options[:token] = token
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit!
      end
    end

    opts.parse!(args)

    if validate_options(options)
      options
    else
      puts opts
      exit!
    end
  end

  def self.load_options_from_config
    options = {}
    env_array = ENV.select { |key, value| key =~ /^PIVOTALTRACKER/ }
    env_array.each do |entry|
      options[entry[0].downcase.sub(/^pivotaltracker_/, '').intern] = entry[1]
    end
    
    if File.exist?(".pivotal_tracker")
      config = YAML::load(IO.read(".pivotal_tracker"))
      if config
        config.inject(options) do |options, option|
          options[option[0].to_sym] = option[1]
        end
      end
    end

    options
  end

  def self.validate_options(options)
    return false if options[:project_id].nil?
    return false if options[:token].nil?
    return true
  end
end