require_relative './init'
require_relative 'lib/user'
require_relative 'lib/om'
require_relative 'lib/rdio'

class Rdiocto < Sinatra::Application
  register Sinatra::AssetPack
  assets {
    js :app, [ '/js/*.js' ]
  }
  enable :sessions

  before do
    p session
    if session[:user_id]
      @user = User.find(session[:user_id])
    end
  end

  get '/' do
    haml :index
  end

  get '/callbacks/github_auth' do
    response = RestClient.post 'https://github.com/login/oauth/access_token', {
      client_id: ENV['GH_CLIENT_ID'],
      client_secret: ENV['GH_CLIENT_SECRET'],
      code: params[:code] },
      :accept => :json
    puts "access token response: #{response.to_s}"
    if response.code.to_i == 200
      token = JSON.parse(response.to_s)["access_token"]
      user = JSON.parse(RestClient.get 'https://api.github.com/user', params: { access_token: token }, :accept => :json)
      puts "user response: #{user.inspect}"
      user = User.create github_username: user["login"], github_key: token
      session[:user_id] = user.id
      redirect '/'
    else
      "Something failed oh noes!"
    end
  end

  get '/authentications/rdio' do
    if @user
      rdio = Rdio.new([ENV['RDIO_CLIENT_ID'], ENV['RDIO_CLIENT_SECRET']])
      callback_url = (URI.join request.url, '/callbacks/rdio_auth').to_s
      url = rdio.begin_authentication(callback_url)
      session[:rdio_token] = rdio.token[0]
      session[:rdio_secret] = rdio.token[1]
      redirect url
    else
      "you need to log in to github first"
    end
  end

  get '/callbacks/rdio_auth' do
    rdio = Rdio.new([ENV['RDIO_CLIENT_ID'], ENV['RDIO_CLIENT_SECRET']],
                    [session[:rdio_token], session[:rdio_secret]])
    rdio.complete_authentication(params['oauth_verifier'])
    user = rdio.call('currentUser')['result']
    @user.rdio_username = File.basename(user['url'])
    @user.rdio_key = rdio.token[0]
    @user.rdio_secret = rdio.token[1]
    @user.save
    p user
    "calllllllled back, sir!"
  end
end


