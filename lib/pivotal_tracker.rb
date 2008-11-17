dir = File.join(File.dirname(__FILE__), 'pivotal_tracker')

Dir["#{dir}/**/*.rb"].each do |file|
  require file
end
