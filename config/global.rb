# configuration for all environments

configure do
  use Rack::Session::Pool, :expire_after => 2592000
  set :session_secret, 'help me obi wan kenobi youre my only hope'
  set :views, File.join(settings.root, 'templates')
  set :haml, :format => :html5

  # enable heroku realtime logging;
  # see https://devcenter.heroku.com/articles/ruby#logging
  $stdout.sync = true
end

configure :production, :development do
  # this is defined by Heroku in production, by your .env file in development
  uri = URI.parse(ENV['REDISTOGO_URL'])
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  MONGO = Mongo::Connection.new(db.host, db.port).db(db_name)
  MONGO.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  verifyDB = MONGO.collection("verify")

  # configure mongo database
  MONGO.collection("users").ensure_index([['username', Mongo::ASCENDING ]], { :unique => true })
  MONGO.collection("verify").ensure_index([['verifyCode', Mongo::ASCENDING ]], { :unique => true, :expireAfterSeconds => 3600})
end

configure :production do
  puts "PROD ENV!!!"

  # force ssl connections only
  require 'rack-ssl-enforcer'
  use Rack::SslEnforcer

  # don't show exceptions
  set :raise_errors, Proc.new { false }
  set :show_exceptions, false
end

configure :test do
  # TODO: mock redis?
end
