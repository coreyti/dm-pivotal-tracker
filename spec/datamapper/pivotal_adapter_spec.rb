require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'pivotal_tracker'

describe DataMapper::Adapters::PivotalAdapter do
  attr_reader :adapter
  
  before(:all) do
    # puts "<pre>"
    DataMapper.setup(:pivotal, { :adapter => 'pivotal' })
    @adapter = DataMapper::Repository.adapters[:pivotal]
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
    it "gets a Resource" do
      mock.proxy(URI).parse('http://www.pivotaltracker.com/services/v1/projects/100/stories/200') do |resource_uri|
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

        mock.instance_of(Net::HTTP).get(
          resource_uri.path,
          {
            'Token' => ENV['PIVOTAL_TOKEN'],
          }
        )
        resource_uri
      end

      resource = PivotalTracker::Story.first(:id => 200, :project_id => 100)

      resource.should be_an_instance_of(PivotalTracker::Story)
      resource.id.should == 200
      resource.url.should == 'http://www.pivotaltracker.com/story/show/200'
      resource.project_id.should == 100
    end
  end

  describe "Resource.all" do
    it "gets a set of Resources" do
      mock.proxy(URI).parse('http://www.pivotaltracker.com/services/v1/projects/100/stories') do |resource_uri|
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
              <story>
                <id type="integer">300</id>
                <name>ChickenHead</name>
                <url>http://www.pivotaltracker.com/story/show/300</url>
                <project_id>100</project_id>
              </story>
            </response>
            XML
          }
          response
        end

        mock.instance_of(Net::HTTP).get(
          resource_uri.path,
          {
            'Token' => ENV['PIVOTAL_TOKEN'],
          }
        )
        resource_uri
      end

      
      resources = PivotalTracker::Story.all(:project_id => 100)

      resources.length.should == 2
      resources.all? { |resource| resource.is_a? PivotalTracker::Story }.should be_true
      resources.all? { |resource| resource.project_id.should == 100 }.should be_true

      resource = resources.first
      resource.id.should == 200
      resource.name.should == 'LaLa'
      resource.url.should == 'http://www.pivotaltracker.com/story/show/200'
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
        '<story><project_id>100</project_id><name>LaLa</name></story>',
        {
          'Token'        => ENV['PIVOTAL_TOKEN'],
          'Content-Type' => 'application/xml'
        }
      )
      resource_uri
    end
  end
end
