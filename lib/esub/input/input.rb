require 'eventmachine'
require 'evma_httpserver'
require 'logger'

module ESub::Input

  class InputTCPConnection < EM::Connection

    def initialize(config, logger, *args)
      super(*args)
      @config = config
      @logger = logger
    end

    def post_init
      super
      logger.info "New connection #{self}"
    end

    def unbind
      super
      logger.info "Closed connection #{self}"
    end

    def to_s
      "#{self.class}"
    end

    def receive_data(data)
    end

    protected

    def config
      @config
    end

    def logger
      @logger
    end

  end

  class InputHTTPConnection < EM::Connection
    include EM::HttpServer

    def initialize(config, logger, *args)
      super(*args)
      @config = config
      @logger = logger
    end

    def post_init
      super
      logger.info "New connection #{self}"
    end

    def unbind
      super
      logger.info "Closed connection #{self}"
    end

    def process_http_request
      # the http request details are available via the following instance variables:
      #   @http_protocol
      #   @http_request_method
      #   @http_cookie
      #   @http_if_none_match
      #   @http_content_type
      #   @http_path_info
      #   @http_request_uri
      #   @http_query_string
      #   @http_post_content
      #   @http_headers
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      response.content = '<center><h1>Hi there</h1></center>'
      response.send_response
    end

    def to_s
      "#{self.class}"
    end

    protected

    def config
      @config
    end

    def logger
      @logger
    end

  end

  class MainTask

    def initialize(config)
      @config = config
      config.log_dir_path = '/tmp/emergency_submitter'
      config.input_tcp_addr = '0.0.0.0'
      config.input_tcp_port = 9000
      config.input_http_addr = '0.0.0.0'
      config.input_http_port = 9001
      config.input_thread_pool_size = 32
    end

    def start
      tcp_logger = Logger.new(File.join(config.log_dir_path, 'input_tcp'))
      tcp_logger.level = Logger::DEBUG

      http_logger = Logger.new(File.join(config.log_dir_path, 'input_http'))
      http_logger.level = Logger::DEBUG

      EM.threadpool_size = config.input_thread_pool_size

      EM.run do
        EM.start_server(
          config.input_tcp_addr,
          config.input_tcp_port,
          ESub::Input::InputTCPConnection,
          config,
          tcp_logger
        )

        EM::start_server(
          config.input_http_addr,
          config.input_http_port,
          ESub::Input::InputHTTPConnection,
          config,
          http_logger
        )
      end

    end

    protected

    def config
      @config
    end

  end

end
