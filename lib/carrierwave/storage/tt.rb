# encoding: utf-8
require 'carrierwave'
begin
  require 'rest_client'
  RestClient.log = nil
rescue LoadError
  raise "You don't have the 'rest_client' gem installed"
end

module CarrierWave
  module Storage

    class TT < Abstract

      class Connection
        def initialize(options={})
          @tt_host = options[:tt_host]
          @tt_port = options[:tt_port]
          @tt_domain = options[:tt_domain]
          @connection_options     = options[:connection_options] || {}
          @@http ||= new_rest_client
          @@http = new_rest_client if @@http.url != "#{@tt_host}:#{@tt_port}"
        end
        
        def new_rest_client
          RestClient::Resource.new("#{@tt_host}:#{@tt_port}")
        end

        def put(path, payload, headers = {})
          @@http["#{escaped(path)}"].put(payload, headers)
        end

        def get(path, headers = {})
          @@http["#{escaped(path)}"].get(headers)
        end

        def delete(path, headers = {})
          @@http["#{escaped(path)}"].delete(headers)
        end

        def post(path, payload, headers = {})
          @@http["#{escaped(path)}"].post(payload, headers)
        end

        def escaped(path)
          CGI.escape(path)
        end
      end

      class File

        def initialize(uploader, base, path)
          @uploader = uploader
          @path = path
          @base = base
        end

        ##
        # Returns the current path/filename of the file on Cloud Files.
        #
        # === Returns
        #
        # [String] A path
        #
        def path
          @path
        end

        ##
        # Reads the contents of the file from Cloud Files
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          object = tt_connection.get(@path)
          @headers = object.headers
          object.net_http_res.body
        end

        ##
        # Remove the file from Cloud Files
        #
        def delete
          begin
            tt_connection.delete(@path)
            true
          rescue Exception => e
            # If the file's not there, don't panic
            nil
          end
        end

        ##
        # Returns the url on the Cloud Files CDN.  Note that the parent container must be marked as
        # public for this to work.
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          if @uploader.tt_domain
            "http://" + @uploader.tt_domain + '/' + @path
          else
            "#{@uploader.tt_host}:#{@uploader.tt_port}/#{@path}"
          end
        end

        def content_type
          headers[:content_type]
        end

        def content_type=(new_content_type)
          headers[:content_type] = new_content_type
        end

        ##
        # Writes the supplied data into the object on Cloud Files.
        #
        # === Returns
        #
        # boolean
        #
        def store(data,headers={})
          tt_connection.put(@path, data,headers)
          true
        end

        private

          def headers
            @headers ||= begin
              tt_connection.get(@path).headers
            rescue
              {}
            end
          end

          def connection
            @base.connection
          end

          def tt_connection
            if @tt_connection
              @tt_connection
            else
              config = {:tt_host => @uploader.tt_host,
                :tt_port => @uploader.tt_port,
                :tt_domain => @uploader.tt_domain
              }
              @tt_connection ||= CarrierWave::Storage::TT::Connection.new(config)
            end
          end

      end

      ##
      # Store the file on TokyoTyrant
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::TT::File] the stored file
      #
      def store!(file)
        cloud_files_options = {'Content-Type' => file.content_type}
        f = CarrierWave::Storage::TT::File.new(uploader, self, uploader.store_path)
        f.store(file.read,cloud_files_options)
        f
      end

      # Do something to retrieve the file
      #
      # @param [String] identifier uniquely identifies the file
      #
      # [identifier (String)] uniquely identifies the file
      #
      # === Returns
      #
      # [CarrierWave::Storage::TT::File] the stored file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::TT::File.new(uploader, self, uploader.store_path(identifier))
      end


    end # CloudFiles
  end # Storage
end # CarrierWave
