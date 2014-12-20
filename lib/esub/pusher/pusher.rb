require 'logger'

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
            Thread.abort_on_exception = true
            redis = Redis.new(:url => config.redis_host)
            logger = Logger.new(File.join(config.log_dir_path, "pusher_#{i}"))
            logger.level = Logger::DEBUG
            _thread_task(logger, redis)
          end
      end
      threads.each { |t| t.join }
    end

    protected

    def config
      @config
    end

    def _thread_task(logger, redis)
      socket = status = nil

      while true

        # A
        flag ||= _read_flag_from_redis(logger, redis)

        # B
        if socket.nil? || status.nil? || status == :ko
          socket = _new_socket(logger, throttler)
          _read_banner(logger, socket) rescue next
        end

        # C
        begin
          _write_flag(logger, socket, flag)
          _parse_result(logger, socket, flag)
          status = :ok
          flag = nil
        rescue Exception => exc
          logger.warn "#{exc}"
          socket.close
          next
        end

      end # while true
    end # _thread_task

    def _new_socket(logger, throttler)
      begin
        socket = throttler.throttle do
          logger.info 'Connecting ...'
          begin
            Net::TCPClient.new(:server => config.host_for_pusher,
              # Timeouts.
              :connect_timeout        => 8,
              :connect_retry_interval => config.min_connect_interval,
              :connect_retry_count    => 0,
              :read_timeout           => 4,

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
              :log_level           => :debug)
          rescue Exception => exc
            logger.warn "#{exc}"
          end
        end
      end while socket.nil?
      logger.info 'Connected.'
      socket
    end

    def _read_banner(logger, socket)
      logger.info 'Reading banner ...'
      logger.info "BANNER: #{socket.gets.inspect}"
      logger.info "BANNER: #{socket.gets.inspect}"
      logger.info "BANNER: #{socket.gets.inspect}"
      logger.info "BANNER: #{socket.gets.inspect}"
    end

    def _read_flag_from_redis(logger, redis)
      logger.info 'Reading from redis ...'
      begin
        list, flag = redis.blpop('flags', :timeout => config.redis_timeout)
      end while flag.nil?
      logger.info("Read from redis: #{list.inspect} #{flag.inspect}")
      flag
    end

    def _parse_result(logger, socket, flag)
      logger.info 'Parsing result ...'
      result = socket.gets
      logger.debug("Result #{flag} => #{result}")
      if !result.nil? && result =~ config.flag_ok_regex
        logger.info "Flag good: #{flag}."
      else
        logger.info "Flag bad: #{flag}."
      end
    end

    def _write_flag(logger, socket, flag)
      logger.info 'Writing flag ...'
      socket.write(flag + "\n")
    end

  end

end
