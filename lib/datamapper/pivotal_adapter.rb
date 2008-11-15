require 'rubygems'
require 'hpricot'
require 'net/http'
require 'uri'
require 'pivotal_tracker'

module DataMapper
  module Adapters
    class PivotalAdapter < AbstractAdapter
      TOKEN = ENV['PIVOTAL_TOKEN']
      SERVER = "https://www.pivotaltracker.com/services/v1"

      def read_one(query)
        # puts "one:  #{query.inspect}"
        query.model.load([100, "http://www.pivotaltracker.com/services/v1/parent_resources/100"], query)
      end
      
      def read_many(query)
        # puts "many: #{query.inspect}"
        Collection.new(query) do |set|
          read(query, set, true)
        end
      end

      private
      
      def read(query, set, many=true)
        model      = query.model
        conditions = query.conditions
        # match_with = many ? :select : :detect

        parent_path   = parent_resource_path(conditions)
        singular_path = model.name.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
        plural_path   = singular_path.pluralize

        resource_uri = URI.parse("http://www.pivotaltracker.com/services/v1#{parent_path}/#{plural_path}")
        response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
          http.get(resource_uri.request_uri, {'Token' => TOKEN})
        end

        doc = Hpricot(response.body).at("response/#{plural_path}")

        (doc/"#{singular_path}").each do |entry|
          set.load([
            entry.at("parent_resource_id").inner_html.to_i,
            entry.at("id").inner_html.to_i,
            entry.at("url").inner_html
          ])
        end
        
        # return result unless many
      end

      def parent_resource_path(conditions)
        path = ""

        conditions.each do |condition|
          operator, property, value = condition
          
          if(property.name.to_s =~ /.*_id$/)
            case property.name
              when :parent_resource_id
                raise "parent_resource_id must be expressed using an Integer" unless value.first.is_a?(Integer)
                case operator
                  when :eql then parent_matcher = value.first
                end
                path << "/#{property.name.to_s.sub(/_id$/, '').pluralize}/#{parent_matcher}"
              else
                raise "#{property.name} not supported as a condition"
            end
          end
        end

        path
      end
    end
  end
end

