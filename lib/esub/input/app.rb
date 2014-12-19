module ESub::Input::App

  def self.start(args)
    opts = ESub::Config.opts_from_args(args)
    unless opts.banner_only?
      config = ESub::Config.parse_config(opts.config_file_path)
      ESub::Input::MainTask.new(config).start
    end
  end

end
