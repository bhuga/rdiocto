require_relative './init'

class Rdiocto < Sinatra::Application
  register Sinatra::AssetPack
  assets {
    js :app, [ '/js/*.js' ]
  }

  get '/' do
    haml :index
  end

  get '/authorizations/github' do

  end

  get '/callbacks/github_auth' do

  end

  get '/authorizations/rdio' do

  end
end


