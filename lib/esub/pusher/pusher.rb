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
        logger.debug('Connecting ...')
        begin
          socket = throttler.throttle do
            begin
              Net::TCPClient.new(:server => config.host_for_pusher,
                # Timeouts.
                :connect_timeout        => 4,
                :connect_retry_interval => config.min_connect_interval,
                :connect_retry_count    => 10,
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
                :log_level           => :trace)
            rescue
              nil
            end
          end
        end while socket.nil?
        logger.debug('Connected.')

        status = nil
        begin
          logger.debug("Reading from redis ...")
          flag = redis.blpop('flags')
          logger.debug("Processing #{flag}")
          socket.write(flag)
          result = socket.gets
          logger.debug("Result #{flag} => #{result}")
            if result =~ config.flag_ok_regex
              logger.info "Flag good: #{flag}."
            else
              logger.info "Flag bad: #{flag}."
            end
          rescue Exception => exc
            logger.warn exc
            status = :error
        end while status.nil? || status != :error # inner while

        logger.info('Something is wrong: resetting connection ...')
        socket.close
      end # outer while
    end # _thread_task

  end

end
