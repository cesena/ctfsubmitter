module ESub::Input::App

  def self.start(args)
    opts = ESub::Config.opts_from_args(args)
    config = ESub::Config.parse_config(opts.config_file_path)
    unless config.banner_only?
      ESub::Input::MainTask.new(config).start
    end
  end

end
