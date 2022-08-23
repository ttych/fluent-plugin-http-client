# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/in_http_client'

# unit tests for HttpClientInput
class HttpClientInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  DEFAULT_CONFIG = %()

  private

  def create_driver(conf = DEFAULT_CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpClientInput).configure(conf)
  end
end
