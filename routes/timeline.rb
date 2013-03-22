# MANAGE TIMELINES
get '/api/team/:team/:id/timeline' do
  # get timeline data
  content_type :json
  return Timeline.new(params[:team], params[:id]).to_json
end

get '/api/team/:team/:id/timeline/:ts' do
  # get timeline event data
  content_type :json
  return Timeline::Event.new(params[:team], params[:id], params[:ts].to_f).to_json
end

post '/api/team/:team/:id/timeline' do
  # create timeline event
  content_type :json
  data = request.env['rack.request.query_hash']
  t = Timeline::Event.new(params[:team], params[:id])
  data.each do |name, value|
    if ! t.instance_variable_get('@'+name).nil? and name != "createDate"
      t.instance_variable_set('@'+name, value)
    end
  end
  t.save()
  return t.to_json
end

put '/api/team/:team/:id/timeline/:ts' do
  # update timeline event
  content_type :json
  data = request.env['rack.request.query_hash']
  t = Timeline::Event.new(params[:team], params[:id], params[:ts].to_f)
  data.each do |name, value|
    if ! t.instance_variable_get('@'+name).nil? and name != "createDate"
      t.instance_variable_set('@'+name, value)
    end
  end
  t.save(params[:ts])
  return t.to_json
end

delete '/api/team/:team/:id/timeline/:ts' do
  # delete incident
  content_type :json
  t = Timeline::Event.new(params[:team], params[:id], params[:ts].to_f)
  t.delete()
  return t.to_json
end
