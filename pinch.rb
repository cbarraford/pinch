# load gems
require 'sinatra'
require 'redis'
require 'mongo'
require 'uri'
require 'cgi'
require 'json'
require 'digest'

# load configuration settings
require_relative 'config/global'

# load shared library
require_relative 'lib'

# load classes
require_relative 'classes/init'

# URL Routing
before '/app/*' do
  forceSessionAuth
end

# ensure api authentication
before '/api/*' do
  protected!
end

# ensure user is a member of the team
before '/*/team/*' do
  if params[:splat].first == "api" or params[:splat].first == "app"
    isMember! params[:splat][1].split("/").first
  else
    return false
  end
end

get '/' do
  if session[:logged_in] = true and not session[:username].nil?
    redirect "/app/user/#{session[:username]}"
  else
    clear_session
    redirect '/login'
  end
end

get '/login' do
  if session[:logged_in] = true and not session[:username].nil?
    redirect "/app/user/#{session[:username]}"
  else
    clear_session
    haml :login, :locals => { :remember_me => session[:remember_me] }
  end
end

get '/logout' do
  clear_session
  redirect '/'
end

post '/login' do
  if(validate(params[:username], params["password"]))
    session[:logged_in] = true
    session[:username] = params[:username]
    if params[:remember_me] == "on"
      session[:remember_me] = params[:username]
    end
    redirect "/app/user/#{params[:username]}"
  else
    haml :login, :locals => { :message => 'Incorrect username and/or password' }
  end
end

get '/verify/:code' do
  if verifyDB.find('verifyCode' => params[:code]).nil?
    #invalid verify code
    haml :verified, locals => { 'succes' => false }
  else
    entity = verifyDB.find( 'verifyCode' => params[:code] )
    u = User.new(entity[:username])
    u.verified = true
    u.update()
    haml :verified, locals => { 'succes' => true }
  end
end

# load other routes
require_relative 'routes/init'
