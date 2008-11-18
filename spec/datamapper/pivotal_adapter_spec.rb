require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'pivotal_tracker'

describe DataMapper::Adapters::PivotalAdapter do
  attr_reader :adapter
  
  before(:all) do
    # puts "<pre>"
    DataMapper.setup(:pivotal, { :adapter => 'pivotal' })
    @adapter = DataMapper::Repository.adapters[:pivotal]

    module TestModule
      class ParentResource < PivotalTracker::Resource
        has n, :pivotal_resources
      end

      class PivotalResource < PivotalTracker::Resource
        belongs_to :parent_resource
      end
    end
  end
  
  after(:all) do
    # puts "</pre>"
  end
  
  it_should_behave_like 'a DataMapper Adapter'

  describe "Resource.create" do
    describe "when invoked for a non-nested Resource" do
      it "successfully creates" do
        mock_create('http://www.pivotaltracker.com/services/v1/projects/100/stories')
        resource = PivotalTracker::Story.create(:name => 'LaLa', :project_id => 100)
        resource.id.should == 200
        resource.url.should == 'http://www.pivotaltracker.com/story/show/200'
      end
    end
    
    describe "when invoked through a Resource association" do
      it "successfully creates" do
        pending "CTI: commented code works, but I'm too tired to finish the test right now"
        # project = PivotalTracker::Project.first(:id => 294)
        # story   = project.stories.create(:name => 'PivotalAdapter test', :requested_by => 'Corey Innis')

        # TODO: CTI - something like:
        # mock_create('http://www.pivotaltracker.com/services/v1/pivotal_resources')
        # 
        # resource = TestModule::PivotalResource.new()
        # resource.id.should be_nil
        # resource.url.should be_nil
        # 
        # resource.save
        # resource.id.should_not be_nil
        # resource.url.should match(/^http/)
      end
    end
  end
  
  describe "Resource.first" do
    describe "when invoked for a non-nested Resource" do
      it "gets a Resource" do
        mock_request('http://www.pivotaltracker.com/services/v1/pivotal_resources/200')
        resource = TestModule::PivotalResource.first(:id => 200)

        resource.should be_an_instance_of(TestModule::PivotalResource)
        resource.id.should == 200
        resource.url.should == 'http://localhost/parent_resources/100/pivotal_resources/200'
        resource.parent_resource_id.should == 100
      end
    end
  end

  describe "Resource.all" do
    describe "when invoked for a non-nested Resource" do
      it "gets a set of Resources" do
        mock_request('http://www.pivotaltracker.com/services/v1/pivotal_resources')
        resources = TestModule::PivotalResource.all
          
        resources.should_not be_nil
        resource = resources.first
        resource.should be_an_instance_of(TestModule::PivotalResource)
        resource.id.should == 200
        resource.url.should == 'http://localhost/parent_resources/100/pivotal_resources/200'
        resource.parent_resource_id.should == 100
      end
    end
    
    describe "when invoked through a Resource association" do
      it "gets a set of resources" do
        mock_parent('http://www.pivotaltracker.com/services/v1/parent_resources/100')
        parent = TestModule::ParentResource.all(:id => 100).first

        resources = parent.pivotal_resources

        mock_request('http://www.pivotaltracker.com/services/v1/parent_resources/100/pivotal_resources')
        resources.should_not be_nil

        resource = resources.first
        resource.should be_an_instance_of(TestModule::PivotalResource)
        resource.id.should == 200
        resource.url.should == 'http://localhost/parent_resources/100/pivotal_resources/200'
        resource.parent_resource_id.should == 100
      end
    end
  end

  def mock_create(target_url)
    mock.proxy(URI).parse(target_url) do |resource_uri|
      mock.proxy(Net::HTTP).start(resource_uri.host, resource_uri.port) do |response| 
        stub(response).body {
          <<-XML
          <response success="true">
            <story>
              <id type="integer">200</id>
              <name>LaLa</name>
              <url>http://www.pivotaltracker.com/story/show/200</url>
              <project_id>100</project_id>
            </story>
          </response>
          XML
        }
        response
      end

      mock.instance_of(Net::HTTP).post(
        resource_uri.path,
        '<story><name>LaLa</name><project_id>100</project_id></story>',
        {
          'Token'        => ENV['PIVOTAL_TOKEN'],
          'Content-Type' => 'application/xml'
        }
      )
      resource_uri
    end
  end
  
  def mock_parent(target_url)
    response = Object.new
    stub(response).body {
      '<response><parent_resource><id>100</id><url>http://localhost/parent_parents/100</url></parent_resource></response>'
    }

    uri = Object.new
    mock(uri).host { 'www.pivotaltracker.com' }
    mock(uri).port { 80 }

    mock(URI).parse(target_url) { uri }
    mock(Net::HTTP).start('www.pivotaltracker.com', 80) { response }
  end

  def mock_request(target_url)
    response = Object.new
    stub(response).body {
      '<response><pivotal_resource><id>200</id><url>http://localhost/parent_resources/100/pivotal_resources/200</url><parent_resource_id>100</parent_resource_id></pivotal_resource></response>'
    }

    uri = Object.new
    mock(uri).host { 'www.pivotaltracker.com' }
    mock(uri).port { 80 }

    mock(URI).parse(target_url) { uri }
    mock(Net::HTTP).start('www.pivotaltracker.com', 80) { response }
  end
end
