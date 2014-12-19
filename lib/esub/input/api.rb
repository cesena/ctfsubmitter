class ESub::Input::API < Sinatra::Base

  configure :production, :development do
    set :show_exceptions => false
    enable :logging
  end

  ##
  # @method create_flag
  # @overload create '/flags'
  #
  # Create a new flag
  #
  # * *REST resource*: `flags`
  # * *REST action*: `create`
  #
  post '/flags', :provides => :json do
    pass unless request.accept? 'application/json'

    flag = nil

    # TODO: Save the flag

    if flag
      flag.to_json
    else
      status 500
      {:reason => 'Another round is already started'}.to_json
    end
  end

  # @method delete_flag
  # @overload destroy '/flags/:id'
  #
  # @param {Integer} id The id of the flag to be removed; if :id is `latest`,
  #                     the last received flag is removed
  #
  # Stop a round
  #
  # * *REST resource*: `flag`
  # * *REST action*: `destroy`
  #
  delete '/flags/:id', :provides => :json do
    pass unless request.accept? 'application/json'

    # TODO: Adapt to redis db
    selected_flags = if params[:id].to_sym == :latest
                        [settings.db[:rounds].last] || []
                      else
                        selected_flags = settings.db[:rounds].select do |round|
                          round.id == (Integer(params[:id]) rescue nil)
                        end
                        if selected_flags.length > 1
                          logger.warn("#{selected_flags.length} flags have the same id")
                        end
                        selected_flags
                      end

    selected_flags.each { |round| round.stop }

    if selected_flags.length > 0
      {}.to_json
    else
      status 500
      {:reason => 'No flags found with the provided identifier'}
    end
  end

  error do |err|
    Rack::Response.new(
      [{:reason => err.message}.to_json],
      500,
      {'Content-type' => 'application/json'}
    ).finish
  end

  # @method not_found
  #
  # Called when no other route matches
  #
  not_found do
    'Not found!'
  end

end
