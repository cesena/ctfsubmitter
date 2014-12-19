module ESub::Pusher::App

  def self.start(args)
    opts = ESub::Config.opts_from_args(args)
    config = ESub::Config.parse_config(opts.config_file_path)
    unless config.banner_only?
      ESub::Pusher::MainTask.new(config).start
    end
  end

end
