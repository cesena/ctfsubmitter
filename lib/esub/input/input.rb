require 'eventmachine'
require 'logger'

module ESub::Input

  class MainTask

    def initialize(config)
      @config = config
    end

    def start
      tcp_logger = Logger.new(File.open(
          File.join(config.log_dir_path, 'input_tcp'),
          File::WRONLY | File::APPEND | File::CREAT)
      )
      tcp_logger.level = Logger::DEBUG
      http_logger = Logger.new(File.open(
          File.join(config.log_dir_path, 'input_http'),
          File::WRONLY | File::APPEND | File::CREAT)
      )
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
        EM.start_server(
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

  class InputTCPConnection < EM::Connection

    def initialize(config, logger)
      @config = config
      @logger = logger
    end

    def post_init
      logger.info "New connection #{self}"
    end

    def unbind
      logger.info "Closed connection #{self}"
    end

    def to_s
      "#{self.class}"
    end

    # TODO logic

    protected

    def config
      @config
    end

    def logger
      @logger
    end

  end

  class InputHTTPConnection < EM::Connection

    def initialize(config, logger)
      @config = config
      @logger = logger
    end

    def post_init
      logger.info "New connection #{self}"
    end

    def unbind
      logger.info "Closed connection #{self}"
    end

    # TODO logic

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

end
