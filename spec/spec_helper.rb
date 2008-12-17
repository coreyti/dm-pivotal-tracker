$LOAD_PATH.unshift File.join(File.dirname(__FILE__), %w[.. lib])

require "rubygems"
require "spec"
require "datamapper"

Spec::Runner.configure do |config|
  config.mock_with :rr

  config.before(:all) do
    # puts "<pre>"
    DataMapper.setup(:pivotal, {
      :adapter => 'pivotal',
      :token   => ENV['PIVOTALTRACKER_TOKEN'],
      :server  => 'http://www.pivotaltracker.com/services/v1'
    })
    @adapter = DataMapper::Repository.adapters[:pivotal]
  end

  config.after(:all) do
    # puts "</pre>"
  end
end

module Spec::Example::ExampleMethods
  attr_reader :adapter
  
  describe "a DataMapper Adapter", :shared => true do
    it "should initialize the connection uri" do
      new_adapter = adapter.class.new(:default, Addressable::URI.parse('some://uri/string'))
      new_adapter.instance_variable_get('@uri').to_s.should == Addressable::URI.parse('some://uri/string').to_s
    end

    %w{create read_many read_one update delete create_model_storage alter_model_storage destroy_model_storage create_property_storage alter_property_storage destroy_property_storage} .each do |meth|
      it "should have a #{meth} method" do
        adapter.should respond_to(meth.intern)
      end
    end
  end

  def mock_read_1(resource_class)
    mock(adapter).read_one(anything) do |query|
      raise "Unexpected query in call to PivotalAdapter#read_one. Query: #{query.inspect}" unless query.model == resource_class

      mocked_result = yield
      values = adapter.send(:read_values, mocked_result, query.fields, query.repository.name) 
      query.model.load(values, query)
    end.ordered
  end
  
  def mock_read_n(resource_class)
    mock(adapter).read_many(anything) do |query|
      raise "Unexpected query in call to PivotalAdapter#read_many. Query: #{query.inspect}" unless query.model == PivotalTracker::Story

      mocked_result = yield
      DataMapper::Collection.new(query) do |collection|
        mocked_result.each do |entry|
          values = adapter.send(:read_values, entry, query.fields, query.repository.name)
          collection.load(values)
        end
      end
    end.ordered
  end

  def mock_read_halt
    stub(adapter).read_one do |query|
      raise "Shouldn't be reading anymore. Called PivotalAdapter#read_one. Query: #{query.inspect}"
    end
    stub(adapter).read_many do |query|
      raise "Shouldn't be reading anymore. Called PivotalAdapter#read_many. Query: #{query.inspect}"
    end
  end

  def mock_get(resource_url)
    resource_uri  = URI.parse(resource_url)
    resource_path = resource_uri.path

    result = yield
    response = result # e.g., Net::HTTPNotFound
    if(result.is_a?(String))
      response = Object.new
      stub(response).body { result }
    end
    
    mock(adapter).http_get(resource_path.sub(/^\/services\/v1/, '')) { response }
  end
  
  def mock_post(resource_url, data)
    resource_uri  = URI.parse(resource_url)
    resource_path = resource_uri.path

    result = yield
    response = result
    if(result.is_a?(String))
      response = Object.new
      stub(response).body { result }
    end
    
    mock(adapter).http_post(resource_path.sub(/^\/services\/v1/, ''), data) { response }
  end
  
  def mock_put(resource_url, data)
    resource_uri  = URI.parse(resource_url)
    resource_path = resource_uri.path

    result = yield
    response = result
    if(result.is_a?(String))
      response = Object.new
      stub(response).body { result }
    end
    
    mock(adapter).http_put(resource_path.sub(/^\/services\/v1/, ''), data) { response }
  end

  def mock_delete(resource_url)
    resource_uri  = URI.parse(resource_url)
    resource_path = resource_uri.path

    result = yield
    response = result
    if(result.is_a?(String))
      response = Object.new
      stub(response).body { result }
    end
    
    mock(adapter).http_delete(resource_path.sub(/^\/services\/v1/, '')) { response }
  end
end

def h(message)
  message.inspect.gsub(/</, '&lt;').gsub(/>/, '&gt;')
end
