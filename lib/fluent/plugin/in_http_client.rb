# frozen_string_literal: true

#
# Copyright 2022- Thomas Tych
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/input'

require 'faraday'
require 'faraday/net_http'
require 'faraday/retry'

module Fluent
  module Plugin
    # HttpClientInput: a plugin to pull http server
    class HttpClientInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input('http_client', self)

      DEFAULT_USER_AGENT = 'fluent-plugin-http-client'

      helpers :timer, :compat_parameters

      # behavior
      desc 'The interval time between request execution'
      config_param :interval, :time, default: 30
      desc 'The tag of the event is emitted on'
      config_param :tag, :string
      # http
      desc 'The url to request'
      config_param :url, :string
      desc 'The http method for each request'
      config_param :http_method, :enum, list: %i[get post delete], default: :get
      desc 'The timeout in second for each request'
      config_param :timeout, :integer, default: 5
      desc 'verify_ssl'
      config_param :verify_ssl, :bool, default: true
      desc 'The absolute path of directory where ca_file stored'
      config_param :ca_path, :string, default: nil
      desc 'The absolute path of ca_file'
      config_param :ca_file, :string, default: nil

      def configure(conf)
        compat_parameters_convert(conf, :parser)

        super

        configure_client
      end

      def start
        super

        timer_execute(:in_http_client_timer, @interval, &method(:on_timer_request))
      end

      private

      def configure_client
        @client = Faraday.new(client_options) do |f|
          f.request :retry
          f.response :json
        end
      end

      def client_options
        {
          url: @url,
          headers: { 'User-Agent' => @user_agent },
          request: { timeout: @timeout },
          ssl: { ca_file: @ca_file,
                 ca_path: @ca_path,
                 verify: @verify_ssl }
        }
      end

      def headers
        { 'User-Agent' => DEFAULT_USER_AGENT }
      end

      def on_timer_request
        base_record = {
          request_url: @url
        }
        begin
          record = do_request
        rescue StandardError => e
          record = parse_exception(e)
        end

        record_time = Engine.now
        record.update(base_record)
        router.emit(tag, record_time, record)
      end

      def do_request
        response = @client.send(@http_method)

        {
          'status' => response.status,
          'success' => response.success?,
          'response' => response.body
        }
      end

      def parse_exception(exception)
        {
          'status' => -1,
          'success' => false,
          'error' => exception.to_s
        }
      end
    end
  end
end
