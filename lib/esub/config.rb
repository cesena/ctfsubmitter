require 'optparse'
require 'yaml'
require 'fileutils'

module ESub::Config

  HEADER = <<-EOS
Usage: #{$0} [options]
EOS

  def self.new_optparser(options)
    OptionParser.new do |p|
      p.banner = HEADER

      p.separator "\nSpecific options:\n"

      p.on('-c', '--config',
          'Parse config from the specified yaml file.') do |s|
        options.config_file_path = s
      end

      p.separator "\nCommon options:\n"

      p.on_tail('-h', '--help', '--usage',
          'Show this usage message and quit.') do
        options.help = true
        puts p.help
      end

      p.on_tail('-v', '--version',
          'Show version information about this program and quit.') do
        options.version = true
        puts ESub.VERSION
      end

      options.optparser = p
    end
  end

  def self.opts_from_args(args)
    options = Hashie::Mash.new
    def options.banner_only?
      help || version
    end

    new_optparser(options).parse! args

    options
  end

  def self.parse_config(config_file_path = nil)
    default_config = Hashie::Mash.new({
      :log_dir_path => '/tmp/submitter/logs',
      :pid_dir_path => '/tmp/submitter/pids',
      :min_connect_interval => 16,
      :pusher_threads => 1,
      :host_for_pusher => '10.10.10.2:31337',
      :input_thread_pool_size => 17,
      :input_tcp_addr => '0.0.0.0',
      :input_tcp_port => 8888,
      :input_http_addr => '0.0.0.0',
      :input_http_port => 8080,
      :input_environment => (ENV['environment'] || 'development'),
      :redis_host => 'redis://127.0.0.1:6379/1',
      :redis_flags_key => 'flags',
      :redis_timeout => 3,
      :flag_ok_regex => /\A.*$/
    })

    override = unless config_file_path.nil?
      YAML.load_file(config_file_path)
    else
      {}
    end

    config = Hashie::Mash.new default_config.merge(override)
    FileUtils.mkdir_p(config.log_dir_path)
    config
  end

end
