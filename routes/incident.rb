# MANAGE INCIDENTS

get '/:type/team/:team/:id' do
  # get incident data
  params[:team].downcase!
  if params[:type] == 'api'
    content_type :json
    return Incident.new(params[:team], params[:id]).to_json
  elsif params[:type] == 'app'
    begin
      s = Incident.new(params[:team], params[:id])
      # added timeline event that user joined incident if it hasn't been added already
      found = false
      m = "#{session['username']} joined the incident."
      puts s.to_hash
      s.timeline.events.each do | event |
        found = true if event.message == m
      end
      if found == false
        e = Timeline::Event.new(params[:team], params[:id], { 'message' => m, 'severity' => "atomic", 'author' => 'Pinch', 'silent' => true })
        e.save
      end
      haml :incident, :locals => { :incident => s.to_hash }
    rescue IncidentError
      haml :error, :locals => { :message => "Sorry, that incident(#{params[:id]}) does not seem to exist for this team (#{params[:team]})" }
    end
  end
end

post '/:type/team/:team/incident' do
  # create incident
  params[:team].downcase!
  if params[:type] == "api"
    content_type :json
    return Incident.new(params[:team]).to_json
  else
    s = Incident.new(params[:team])
    t = Team.new(params[:team].downcase)
    t.populateTeamDetail
    t.addIncident(s.id)
    t.save
    redirect "/app/team/#{params[:team]}/#{s.id}"
  end
end

put '/api/team/:team/:id' do
  # update incident data
  content_type :json
  data = request.env['rack.request.query_hash']
  params[:team].downcase!
  s = Incident.new(params[:team], params[:id])
  data.each do |name, value|
    if ! s.instance_variable_get("@"+name).nil? and name != "createDate" # createDate cannot be changed
      s.instance_variable_set("@"+name, value)
    end
  end
  return s.to_json
end

post '/app/team/:team/:id' do
  params[:team].downcase!
  Incident.new(params[:team], params[:id]).delete
  redirect("/app/team/#{params[:team]}")
end

delete '/api/team/:team/:id' do
  # delete incident
  params[:team].downcase!
  Incident.new(params[:team], params[:id]).delete
  content_type :json
  return "OK".to_json
end
