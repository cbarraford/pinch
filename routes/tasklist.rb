# MANAGE TASKLISTS

get '/api/team/:team/:id/tasklist' do
  # get tasklist data
  content_type :json
  return Tasklist.new(params[:team], params[:id]).to_json
end

get '/api/team/:team/:id/tasklist/:ti' do
  # get tasklist event data
  content_type :json
  return Tasklist::Item.new(params[:team], params[:id], params[:ti].to_i).to_json
end

post '/api/team/:team/:id/tasklist' do
  # create tasklist event
  content_type :json
  data = request.env['rack.request.query_hash']
  t = Tasklist::Item.new(params[:team], params[:id])
  data.each do |name, value|
    if ! t.instance_variable_get('@'+name).nil? and name != "createDate"
      t.instance_variable_set('@'+name, value)
    end
  end
  t.save()
  # create timeline event for creation of new task
  e = Timeline::Event.new(params[:team], params[:id], { 'message' => "#{t.author} created new task item: #{t.description}", 'severity' => "atomic", 'author' => 'Pinch', 'silent' => t.silent })
  e.save
  return t.to_json
end

put '/api/team/:team/:id/tasklist/:ti' do
  # update tasklist event
  content_type :json
  data = request.env['rack.request.query_hash']
  t = Tasklist::Item.new(params[:team], params[:id], params[:ti].to_i)
  old_owner = t.owner
  old_state = t.state
  data.each do |name, value|
    if ! t.instance_variable_get('@'+name).nil? and name != "createDate"
      t.instance_variable_set('@'+name, value)
    end
  end
  t.save(params[:ti])

  # create timeline event if owner or state changed
  if old_owner != t.owner
    e = Timeline::Event.new(params[:team], params[:id], { 'message' => "#{t.owner} just became the owner of task item: #{t.description}", 'severity' => "atomic", 'author' => 'Pinch', 'silent' => t.silent })
    e.save    
  end
  if old_state != t.state
    e = Timeline::Event.new(params[:team], params[:id], { 'message' => "Task is now #{t.state}: #{t.description}", 'severity' => "atomic", 'author' => 'Pinch', 'silent' => t.silent })
    e.save
  end
  return t.to_json
end

delete '/api/team/:team/:id/tasklist/:ti' do
  # delete incident
  content_type :json
  t = Tasklist::Item.new(params[:team], params[:id], params[:ti].to_i)
  t.delete()
  return t.to_json
end
