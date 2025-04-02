# frozen_string_literal: true

require 'webrick'
require 'json'

class TestWebServer
  attr_reader :port

  def initialize(port: 8000)
    @port = port
    @server_thread = nil
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      DocumentRoot: '.',
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
  end

  def mount(path, status: 200, headers: {}, body: {})
    @server.mount_proc path do |_req, res|
      res.status = status
      headers.each { |key, value| res[key] = value }
      res['Content-Type'] ||= 'application/json' unless headers.key?('Content-Type')
      res.body = body.is_a?(String) ? body : body.to_json
    end
  end

  def start
    @server_thread = Thread.new { @server.start }
    sleep 1
  end

  def stop
    @server.shutdown
    Thread.kill(@server_thread) if @server_thread
  end
end
