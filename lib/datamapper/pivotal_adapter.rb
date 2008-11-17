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

      def create(resources)
        created = 0

        resources.each do |resource|
          repository = resource.repository
          model      = resource.model
          options    = write_options(model, resource)
          
          # identity_field = model.key(repository.name).detect { |p| p.serial? }
          result = do_post(options, resource.to_xml)
          unless result.empty?
            resource.attributes = result
            # TODO: CTI - would rather use this technique:
            # values = read_values(result, attributes, repository)
            # model.load(values, resource)

            created += 1
          end
        end
        
        created
      end
      
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
        options     = read_options(query.model, query.conditions)
        repository  = query.repository.name
        properties  = query.fields
        
        results = do_get(options)

        results.each do |result|
          values = read_values(result, properties, repository)
          many ? set.load(values) : (break set.load(values, query))
        end
      end
      
      def read_options(model, conditions)
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

      def read_values(result, properties, repository)
        properties.map { |property| result[property.field(repository).intern] }
      end

      def write_options(model, resource)
        options = {
          :ancestry => '',
          :resource => path_segment(model)
        }
        
        resource.loaded_attributes.each do |attribute|
          if attribute.to_s =~ /.*_id$/
            options.merge!(:ancestry => (options[:ancestry] + tmp_segment(attribute, resource.attribute_get(attribute))))
          end
        end
        
        options
      end

      def do_post(options, xml_data)
        result = {}

        resource_uri = URI.parse("#{SERVER}#{options[:ancestry]}#{options[:resource]}")
        headers = {
          'Token'        => TOKEN,
          'Content-Type' => 'application/xml'
        }
        
        response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
          http.post(
            resource_uri.path,
            xml_data,
            headers
          )
        end
        
        doc = Hpricot(response.body).at("response")
        
        # TODO: CTI - There's only one, so quit yer looping
        (doc/"/#{options[:resource]}").each do |entry|
          entry.children.each do |child|
            if child.is_a?(Hpricot::Elem)
              as_int = child.inner_html.to_i
              result[child.name.intern] = (as_int == 0 ? child.inner_html : as_int)
            end
          end
        end
        
        result
      end

      def do_get(options)
        results = []

        resource_uri = URI.parse("#{SERVER}#{options[:ancestry]}#{options[:resource]}")
        response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
          # get(path, initheader = nil, dest = nil) {|+body_segment+| ...}   
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

      def path_segment(property, value=nil)
        value = value.first if value.is_a?(Array)
        singular = property.name.to_s.split('::').last.to_s.sub(/_id$/, '')
        singular = singular.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
        "/#{singular.pluralize}#{value ? '/' + value.to_s : ''}"
      end
      
      def tmp_segment(attribute, value)
        singular = attribute.to_s.sub(/_id$/, '')
        singular = singular.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
        "/#{singular.pluralize}#{value ? '/' + value.to_s : ''}"
      end
    end
  end
end

