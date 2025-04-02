# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/in_http_client'

# unit tests for HttpClientInput
class HttpClientInputTest < Test::Unit::TestCase
  TEST_TIME = '2025-04-03T02:01:00.123Z'
  TEST_FLUENT_TIME = Fluent::EventTime.parse(TEST_TIME)

  TEST_TAG = 'test'
  TEST_TAG_STATUS = 'test_status'
  TEST_URL = 'http://localhost'
  DEFAULT_CONFIG = %(
    tag #{TEST_TAG}
    url #{TEST_URL}
  ).freeze

  setup do
    Fluent::Test.setup

    Fluent::EventTime.stubs(:now).returns(TEST_FLUENT_TIME)
  end

  sub_test_case 'configuration' do
    test 'default configuration' do
      driver = create_driver
      input = driver.instance

      assert_equal input.tag, input.tag_status
      assert_equal 60, input.interval

      assert_equal :get, input.http_method
      assert_equal 5, input.timeout
      assert_equal nil, input.ca_path
      assert_equal nil, input.ca_file
      assert_equal 'fluent-plugin-http-client', input.user_agent
      assert_equal nil, input.user
      assert_equal nil, input.password

      assert_equal true, input.enable_status
      assert_equal true, input.status_with_response_data
      assert_equal false, input.enable_response_data
      assert_equal false, input.split_response_data
      assert_equal false, input.enable_failed_response_data
    end

    test 'can inject tag' do
      driver = create_driver
      input = driver.instance

      assert_equal 'test', input.tag
    end

    test 'tag is mandatory' do
      conf = %(
        url http://localhost
      )

      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end

    test 'can inject url' do
      driver = create_driver
      input = driver.instance

      assert_equal 'http://localhost', input.url
    end
  end

  sub_test_case 'with mocked http client' do
    sub_test_case 'on request error' do
      test 'it emits status events' do
        http_client = mock_http_client
        http_client.stubs(:get).raises(StandardError.new('Test error'))

        driver = create_driver
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'error' => 'Test error',
             'request_url' => TEST_URL,
             'status' => -1,
             'success' => false }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it emits status events on tag_status' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
        )
        http_client = mock_http_client
        http_client.stubs(:get).raises(StandardError.new('Test error'))

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'error' => 'Test error',
             'request_url' => TEST_URL,
             'status' => -1,
             'success' => false }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end
    end

    sub_test_case 'when request is in success' do
      test 'it emits status events' do
        http_client = mock_http_client
        http_response = mock_http_client_response(body: { 'data' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 200,
             'success' => true,
             'response' => { 'data' => 'test' } }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it emits status events on tag_status' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(body: { 'data' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 200,
             'success' => true,
             'response' => { 'data' => 'test' } }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it emits response data' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
          enable_response_data true
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(body: { 'data' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 200,
             'success' => true,
             'response' => { 'data' => 'test' } }],
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'data' => 'test' }]
        ]

        assert_equal 2, events.size
        assert_equal expected_events, events
      end

      test 'it emits splitted response data when requested' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
          status_with_response_data false
          enable_response_data true
          split_response_data true
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(
          body: [{ 'data1' => 'test1' }, { 'data2' => 'test2' }]
        )
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 200,
             'success' => true }],
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'data1' => 'test1' }],
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'data2' => 'test2' }]
        ]

        assert_equal 3, events.size
        assert_equal expected_events, events
      end
    end

    sub_test_case 'when request is not in success' do
      test 'it emits status events' do
        http_client = mock_http_client
        http_response = mock_http_client_response(status: 400, body: { 'error' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 400,
             'success' => false,
             'response' => { 'error' => 'test' } }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it emits status events on tag_status' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(status: 400, body: { 'error' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 400,
             'success' => false,
             'response' => { 'error' => 'test' } }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it does not emit response data when requested' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
          enable_response_data true
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(status: 400, body: { 'error' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 400,
             'success' => false,
             'response' => { 'error' => 'test' } }]
        ]

        assert_equal 1, events.size
        assert_equal expected_events, events
      end

      test 'it emits response data when requested' do
        conf = %(
          #{DEFAULT_CONFIG}
          tag_status #{TEST_TAG_STATUS}
          enable_response_data true
          enable_failed_response_data true
        )
        http_client = mock_http_client
        http_response = mock_http_client_response(status: 400, body: { 'error' => 'test' })
        http_client.stubs(:get).returns(http_response)

        driver = create_driver(conf)
        input = driver.instance

        input.send(:request)
        events = driver.events

        expected_events = [
          [TEST_TAG_STATUS,
           TEST_FLUENT_TIME,
           { 'request_url' => TEST_URL,
             'status' => 400,
             'success' => false,
             'response' => { 'error' => 'test' } }],
          [TEST_TAG,
           TEST_FLUENT_TIME,
           { 'error' => 'test' }]
        ]

        assert_equal 2, events.size
        assert_equal expected_events, events
      end
    end
  end

  sub_test_case 'with test web server' do
    test 'success request' do
      server = test_web_server
      conf = %(
        url http://localhost:8000/success
        tag #{TEST_TAG}
        tag_status #{TEST_TAG_STATUS}
        enable_response_data true
      )

      driver = create_driver(conf)
      input = driver.instance

      input.send(:request)
      events = driver.events

      expected_events = [
        [TEST_TAG_STATUS,
         TEST_FLUENT_TIME,
         { 'request_url' => 'http://localhost:8000/success',
           'status' => 200,
           'success' => true,
           'response' => { 'message' => 'OK' } }],
        [TEST_TAG,
         TEST_FLUENT_TIME,
         { 'message' => 'OK' }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    ensure
      server.stop
    end

    test 'failed request' do
      server = test_web_server
      conf = %(
        url http://localhost:8000/not_found
        tag #{TEST_TAG}
        tag_status #{TEST_TAG_STATUS}
        enable_response_data true
      )

      driver = create_driver(conf)
      input = driver.instance

      input.send(:request)
      events = driver.events

      expected_events = [
        [TEST_TAG_STATUS,
         TEST_FLUENT_TIME,
         { 'request_url' => 'http://localhost:8000/not_found',
           'status' => 404,
           'success' => false,
           'response' => { 'error' => 'Not Found' } }]
      ]

      assert_equal 1, events.size
      assert_equal expected_events, events
    ensure
      server.stop
    end
  end

  private

  def test_web_server
    server = TestWebServer.new

    server.mount('/success', status: 200, body: { message: 'OK' })
    server.mount('/not_found', status: 404, body: { error: 'Not Found' })

    server.start
    server
  end

  def mock_http_client
    mock_client = mock('http_client')
    Faraday.stubs(:new).returns(mock_client)
    mock_client
  end

  def mock_http_client_response(status: 200, headers: nil, body: nil)
    Faraday::Response.new(
      status: status || 200,
      response_headers: headers || { 'Content-Type' => 'application/json' },
      body: body || { 'message' => 'Success' }
    )
  end

  def create_driver(conf = DEFAULT_CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpClientInput).configure(conf)
  end
end
