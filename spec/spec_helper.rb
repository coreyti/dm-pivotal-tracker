$LOAD_PATH.unshift File.join(File.dirname(__FILE__), %w[.. lib])

require "rubygems"
require "spec"
require "datamapper"

Spec::Runner.configure do |config|
  config.mock_with :rr
end

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

def h(message)
  message.gsub(/</, '&lt;').gsub(/>/, '&gt;')
end

module Spec::Example::ExampleMethods
  def mock_get(resource_url)
    resource_uri  = URI.parse(resource_url)
    resource_path = resource_uri.path

    result = yield
    response = result # e.g., Net::HTTPNotFound
    if(result.is_a?(String))
      response = Object.new
      stub(response).body { result }
    end
    
    mock(Net::HTTP::Get).new(resource_path, { 'Token' => ENV['PIVOTAL_TOKEN'] })
    mock.instance_of(Net::HTTP).request(anything)

    mock.proxy(Net::HTTP).start('www.pivotaltracker.com', 80)
    mock.proxy(adapter).request { response }
  end
end
