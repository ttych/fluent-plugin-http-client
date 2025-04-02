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

      DEFAULT_INTERVAL = 60
      DEFAULT_HTTP_METHOD = :get
      DEFAULT_USER_AGENT = 'fluent-plugin-http-client'
      DEFAULT_TIMEOUT = 5

      helpers :timer, :compat_parameters

      desc 'The tag of the event is emitted on'
      config_param :tag, :string
      desc 'The tag of the event is emitted on'
      config_param :tag_status, :string, default: nil

      desc 'The interval time between request execution'
      config_param :interval, :time, default: DEFAULT_INTERVAL

      desc 'The url to request'
      config_param :url, :string
      desc 'The http method for each request'
      config_param :http_method, :enum, list: %i[get post delete put patch head options], default: DEFAULT_HTTP_METHOD
      desc 'The timeout in second for each request'
      config_param :timeout, :integer, default: DEFAULT_TIMEOUT
      desc 'verify_ssl'
      config_param :verify_ssl, :bool, default: true
      desc 'The absolute path of directory where ca_file stored'
      config_param :ca_path, :string, default: nil
      desc 'The absolute path of ca_file'
      config_param :ca_file, :string, default: nil
      desc 'The user agent string of request'
      config_param :user_agent, :string, default: DEFAULT_USER_AGENT
      desc 'user of basic auth'
      config_param :user, :string, default: nil
      desc 'password of basic auth'
      config_param :password, :string, default: nil, secret: true

      desc 'enable status events'
      config_param :enable_status, :bool, default: true
      desc 'status events with response data'
      config_param :status_with_response_data, :bool, default: true
      desc 'enable response data events'
      config_param :enable_response_data, :bool, default: false
      desc 'split response data when array'
      config_param :split_response_data, :bool, default: false
      desc 'enable response data events on failure'
      config_param :enable_failed_response_data, :bool, default: false

      def configure(conf)
        compat_parameters_convert(conf, :parser)

        super

        check_mandatory_params
        configure_tag
        configure_client
      end

      def start
        super

        timer_execute(:in_http_client_timer, interval, &method(:request))
      end

      private

      def check_mandatory_params
        raise Fluent::ConfigError, 'url should not be empty' if url.nil? || url.empty?

        true
      end

      def configure_tag
        @tag_status ||= @tag

        raise Fluent::ConfigError, 'tag or tag_status should be defined' if enable_status && !tag_status
        raise Fluent::ConfigError, 'tag should be defined' if enable_response_data && !tag

        true
      end

      def configure_client
        @client = Faraday.new(client_options) do |f|
          f.request :retry
          f.request :authorization, :basic, user, password if user && password
          f.response :json
        end
      end

      def client_options
        {
          url: url,
          headers: { 'User-Agent' => user_agent },
          request: { timeout: timeout },
          ssl: { ca_file: ca_file,
                 ca_path: ca_path,
                 verify: verify_ssl }
        }
      end

      def request
        request_time = Engine.now
        response = send_request
        emit_status(request_time, response)
        emit_response(request_time, response)
      rescue StandardError => e
        emit_exception(request_time, e)
      end

      def send_request
        @client.send(http_method)
      end

      def emit_status(time, response)
        return unless enable_status

        record = {
          'request_url' => url,
          'status' => response.status,
          'success' => response.success?
        }
        record.update('response' => response.body) if status_with_response_data

        router.emit(tag_status, time, record)
      end

      def emit_response(time, response)
        return unless enable_response_data
        return if !response.success? && !enable_failed_response_data

        record = response.body
        if split_response_data && record.is_a?(Array)
          record.each { |record_element| router.emit(tag, time, record_element) }
        else
          router.emit(tag, time, record)
        end
      end

      def emit_exception(time, error)
        return unless enable_status

        record = {
          'request_url' => url,
          'status' => -1,
          'success' => false,
          'error' => error.to_s
        }

        router.emit(tag_status, time, record)
      end
    end
  end
end
