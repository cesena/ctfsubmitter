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
      while true
        begin
          socket = throttler.throttle do
            logger.info('Connecting ...')
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
                :buffered            => false,
                :keepalive           => false,
                :keepidle            => 4,
                :keepinterval        => 8,
                :keepcount           => 4,

                # Logging.
                :logger              => logger,
                :log_level           => :trace)
            rescue
              nil
            end
          end
        end while socket.nil?
        logger.info('Connected.')

        status = _parse_banner(logger, socket)

        while !status.nil? && status != :error # inner while
          status = nil
          begin
            logger.debug("Reading from redis ...")
            list, flag = redis.blpop('flags', :timeout => config.redis_timeout)
            logger.debug("Processing #{list.inspect} #{flag.inspect}")
            next if flag.nil?
            socket.write(flag + "\n")
            result = socket.gets
            logger.debug("Result #{flag} => #{result}")
            if !result.nil? && result =~ config.flag_ok_regex
              logger.info "Flag good: #{flag}."
            else
              logger.info "Flag bad: #{flag}."
            end
          rescue Exception => exc
            logger.warn exc
            status = :error
          end
        end

        throttler.throttle do
          logger.info('Something is wrong: resetting connection ...')
          socket.close
        end
      end # outer while
    end # _thread_task

    def _parse_banner(logger, socket)
      logger.info 'Parsing banner ...'
      begin
        logger.info "BANNER: #{socket.gets.inspect}"
        logger.info "BANNER: #{socket.gets.inspect}"
        logger.info "BANNER: #{socket.gets.inspect}"
        logger.info "BANNER: #{socket.gets.inspect}"
      rescue Exception => exc
        logger.warn exc
        return :error
      end
      :ok
    end

  end

end
