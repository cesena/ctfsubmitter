# CTF-o-MATOR
# [
#   { "flag":"THE FLAG HERE",
#     "prio":"PRIORITY OF THE ATTACK",
#     "a":"SCRIPT NAME USED FOR THE ATTACK, CAN BE NULL",
#     "t":"ATTACKED TEAM",
#     "s":"ATTACKED SERVICE"},
#   { "flag":"THE FLAG HERE",
#     "prio":"PRIORITY OF THE ATTACK",
#     "a":"SCRIPT NAME USED FOR THE ATTACK, CAN BE NULL",
#     "t":"ATTACKED TEAM",
#     "s":"ATTACKED SERVICE"},
#   ...
# ]

class ESub::Input::API < Sinatra::Base

  configure :production, :development do
    set :show_exceptions => false
    enable :logging
    $redis = Redis.new(:url => 'redis://127.0.0.1:6379/1') # OMG!
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

    begin
      flag = params[:flag]
      unless flag.nil?
        result = $redis.brpush flag
        {}.to_json
      else
        logger.warn("Nil flag provided!")
      end
    rescue Exception => exc
      logger.warn("Could not insert flag: #{exc.class}: #{exc.message}.")
      status 500
      {:reason => 'Could not insert flag.'}.to_json
    end
  end

  get '/flags', :provides => :json do
    pass unless request.accept? 'application/json'

    begin
      flag = params[:flag]
      unless flag.nil?
        result = $redis.rpush 'flags', flag
        {}.to_json
      else
        logger.warn("Nil flag provided!")
      end
    rescue Exception => exc
      logger.warn("Could not insert flag: #{exc.class}: #{exc.message}.")
      status 500
      {:reason => 'Could not insert flag.'}.to_json
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
