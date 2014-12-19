require 'optparse'
require 'yaml'

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
    default_config = {}

    override = unless config_file_path.nil?
      YAML.load_file(config_file_path)
    else
      {}
    end

    Hashie::Mash.new default_config.merge(override)
  end

end
