require 'logger'
require 'pinchoff'

module ESub::Pusher

  class MainTask

    attr_reader :throttler

    def initialize(config)
      @config = config
      @throttler = Pinchoff::Throttler.new config.min_connect_interval
    end

    def start
      threads = (0...config.pusher_threads).collect do |i|
          Thread.new do
            logger = Logger.new(File.open(
                File.join(config.log_dir_path, "pusher_#{i}"),
                File::WRONLY | File::APPEND | File::CREAT)
            )
            logger.level = Logger::DEBUG
            _thread_task(logger)
          end
      end
      threads.each { |t| t.join }
    end

    protected

    def config
      @config
    end

    def _thread_task(logger)
      while true
        socket = throttler.throttle do
          Net::TCPClient.new(:server => config.host_for_pusher,
            # Timeouts.
            :connect_timeout        => 4,
            :connect_retry_interval => 0,
            :connect_retry_count    => 1,
            :read_timeout           => 5,

            # Error handling.
            :close_on_error      => true,
            :close_on_eof        => true,

            # Socket options.
            :buffered            => true,
            :keepalive           => true,
            :keepidle            => 4,
            :keepinterval        => 8,
            :keepcount           => 4,

            # Logging.
            :logger              => logger,
            :log_level           => :trace
          )
        end

        status = begin
          # TODO: get flag from redis

          # TODO: submit and parse result; reconnect on errors
          socket.write(flag)
          result = socket.gets
          :ok
        rescue
          socket.close
          socket = nil
          status = :error
        end while status == :ok # inner while

      end # outer while
    end # _thread_task

  end

end
