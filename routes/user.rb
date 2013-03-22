# MANAGE USER

get '/app/user/:user' do
  if session["username"] == params[:user]
    u = User.new(params[:user])
    incidents = []
    puts u.to_hash
    (u.adminOf+u.memberOf).each do | team |
      t = Team.new(team['name'])
      team['incidents'].each do | incident |
        s = Incident.new(team['name'], incident)
        tmp = {'id' => s.id, 'team' => team['name'], 'createDate' => s.createDate}
        if t.current_incident == incident
          tmp['open'] = true
        else
          tmp['open'] = false
        end
        incidents << tmp
      end
    end
    incidents = incidents.sort_by { |hsh| hsh[:createDate] }
    begin
      haml :user, :locals => { :user => u.to_public_hash, :incidents => incidents }
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, the user (#{u.username}) doesn't exist." }
    end
  end
end

get '/app/user/:user/join' do
  if session["username"] == params[:user]
    haml :joinTeam, :locals => { :username => params[:user] }
  end
end

get '/users/new' do
  haml :newUser, :locals => { :defaults => { 
    :company => params["company"] 
  }}  
end

post '/users/new' do
  newUser = User.new()
  params.each_pair do | name, value |
    puts name, value
    next if name == "password2"
    if name == "password"
      newUser.instance_variable_set('@'+name, Password::update(value))
    else
      newUser.instance_variable_set('@'+name, value)
    end
  end 
  if not newUser.exist?
    newUser.save
    MONGO.collection('verify').insert( { :verifyCode => Digest::MD5.hexdigest("#{newUser.username}:#{Time.new.utc.to_f}"), :username => newUser.username } ) 
    haml :newUserResult, :locals => { :success => true }
  else
    haml :newUserResult, :locals => { :success => false }
  end 
end
