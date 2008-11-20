require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'pivotal_tracker'

describe DataMapper::Adapters::PivotalAdapter do
  attr_reader :adapter
  
  before(:all) do
    puts "<pre>"
    DataMapper.setup(:pivotal, {
      :adapter => 'pivotal',
      :token   => ENV['PIVOTAL_TOKEN'],
      :server  => 'http://www.pivotaltracker.com/services/v1'
    })
    @adapter = DataMapper::Repository.adapters[:pivotal]
  end
  
  after(:all) do
    puts "</pre>"
  end
  
  it_should_behave_like 'a DataMapper Adapter'
  
  describe "create" do
    
  end
  
  describe "read" do
    describe "PivotalAdapter#read_one" do
      context "when the Resource exists" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1',
            <<-XML
            <response success="true">
              <project>
                <name>Sample Project</name>
              </project>
            </response>
            XML
          )
        end
        
        it "executes an HTTP GET" do
          mock.proxy(adapter).http_get('/projects/1')
          PivotalTracker::Project.get(1)
        end
        
        it "returns the Resource" do
          resource = PivotalTracker::Project.get(1)
          resource.should_not be_nil
          resource.id.should be_an_instance_of(Fixnum)
          resource.id.should == 1
          resource.should be_an_instance_of(PivotalTracker::Project)
        end
      end
      
      context "when the Resource does not exist" do
        
      end
    end
  end

  describe "update" do

  end

  describe "delete" do

  end
end
