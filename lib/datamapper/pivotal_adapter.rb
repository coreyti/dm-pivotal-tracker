require 'rubygems'
require 'hpricot'
require 'net/http'
require 'uri'
# require 'pivotal_tracker'

module DataMapper
  module Adapters
    class PivotalAdapter < AbstractAdapter
      TOKEN = ENV['PIVOTAL_TOKEN']
      SERVER = "http://www.pivotaltracker.com/services/v1"

      def read_one(query)
        read(query, query.model, false)
      end
      
      def read_many(query)
        Collection.new(query) do |set|
          read(query, set, true)
        end
      end

      private
      
      def read(query, set, many=true)
        options     = extract_options(query.conditions, query.model)
        repository  = query.repository.name
        properties  = query.fields
        
        results = fetch_results(options)

        results.each do |result|
          values = result_values(result, properties, repository)
          many ? set.load(values) : (break set.load(values, query))
        end
      end
      
      def extract_options(conditions, model)
        resource_selector = path_segment(model)
        options = {
          :foreign  => {},
          :ancestry => '',
          :resource => resource_selector,
          :selector => resource_selector
        }
        
        conditions.each do |condition|
          operator, property, value = condition
          
          case property.name.to_s
            when 'id'
              options.merge!({
                :known_id => value.to_i,
                :resource => path_segment(model, value)
              })
            when /.*_id$/
              options.merge!({
                :foreign  => (options[:foreign].merge({ property.name => value.first.to_i })),
                :ancestry => (options[:ancestry] + path_segment(property, value))
              })
          end
        end
        
        options
      end

      def fetch_results(options)
        results = []

        resource_uri = URI.parse("#{SERVER}#{options[:ancestry]}#{options[:resource]}")
        response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
          http.get(resource_uri.request_uri, {'Token' => TOKEN})
        end
        
        doc = Hpricot(response.body).at("response")
        
        (doc/"/#{options[:selector].singularize}").each do |entry|
          result = { :id => options[:known_id] }.merge(options[:foreign])
          entry.children.each do |child|
            if child.is_a?(Hpricot::Elem)
              as_int = child.inner_html.to_i
              result[child.name.intern] = (as_int == 0 ? child.inner_html : as_int)
            end
          end
          
          results << result
        end
        
        results
      end
      
      def result_values(result, properties, repository)
        properties.map { |property| result[property.field(repository).intern] }
      end

      def path_segment(property, value=nil)
        value = value.first if value.is_a?(Array)
        singular = property.name.to_s.split('::').last.to_s.sub(/_id$/, '')
        singular = singular.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
        "/#{singular.pluralize}#{value ? '/' + value.to_s : ''}"
      end
    end
  end
end

