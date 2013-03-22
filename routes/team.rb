# MANAGE TEAMS

post '/app/teams/new' do
  newTeam = Team.new()
  params.each_pair do | name, value |
    newTeam.instance_variable_set('@'+name, value)
  end
  newTeam.name.downcase!
  if not newTeam.exists?
    newTeam.admins = [session[:username]]
    newTeam.members = []
    newTeam.requests = []
    newTeam.incidents = []
    newTeam.save
    haml :team, :locals => { :team => newTeam.to_hash }
  else
    haml :error, :locals => { :message => "Sorry, that team already exists" }
  end
end

post '/app/teams/join' do
    puts params
    begin
      team = Team.new(params['team'].downcase)
      team.populateTeamDetail
      team.requests << params['username']
      team.save
      haml :error, :locals => { :message => "Your request to join #{team.name} has been sent" }
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, unable to process your request." }
    end
end

post '/app/team/:team/grant/:user' do
    isAdmin! params[:team]
    begin  
      team = Team.new(params['team'].downcase)
      team.populateTeamDetail
      team.members << params['user']
      team.requests.delete(params['user'])
      team.save
      redirect("/app/team/#{team.name}")
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, unable to process your request." }
    end
end

post '/app/team/:team/deny/:user' do
    isAdmin! params[:team]
    begin
      team = Team.new(params['team'].downcase)
      team.populateTeamDetail
      puts team.to_hash
      team.requests.delete(params['user'])
      team.save
      puts team.to_hash
      redirect("/app/team/#{team.name}")
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, unable to process your request." }
    end
end

post '/app/team/:team/revoke/:user' do
    isAdmin! params[:team]
    begin
      team = Team.new(params['team'].downcase)
      team.populateTeamDetail
      puts team.to_hash
      team.members.delete(params['user'])
      team.admins.delete(params['user'])
      team.save
      puts team.to_hash
      redirect("/app/team/#{team.name}")
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, unable to process your request." }
    end 
end

get '/app/teams/new' do
  haml :newTeam
end

get '/:type/team/:team' do
  # get team data
  params[:team].downcase!
  if params[:type] == "api"
    content_type :json
    return Team.new(params[:team]).to_json
  elsif params[:type] == "app"
    begin
      t = Team.new(params[:team])
      t.populateTeamDetail
      if t.isMember?(session[:username])
        if t.isAdmin?(session[:username])
          admin = true
        else
          admin = false
        end
        haml :team, :locals => { :team => t.to_hash, :admin => admin }
      else
        haml :error, :locals => { :message => "Sorry, you are not a member of this team" }
      end
    rescue TeamError
      haml :error, :locals => { :message => "Sorry, the team #{params[:team]} doesn't exist." }
    end
  end
end

put '/app/team/:team' do
  # update incident data
  params[:team].downcase!
  t = Team.new(params[:team])
  params.each do |name, value|
    if ! t.instance_variable_get('@'+name).nil? and name != "createDate"
      t.instance_variable_set('@'+name, value)
    end
  end
  return t.to_json
end

delete '/app/team/:team' do
  # delete incident
  params[:team].downcase!
  Team.new(params[:team]).delete
  return "OK".to_json
end

