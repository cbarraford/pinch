# SHARED LIBRARY OF FUNCTIONS

# sinatra help functions
helpers do
  def validate(username, password)
    # Put your real validation logic here
    begin
      u = User.new(username)
    rescue
      return false
    end
    return Password::check(password, u.password)
  end
  
  def is_logged_in?
    if session[:logged_in] == true and not session[:username].nil?
      return true
    else
      return false
    end
  end

  def forceSessionAuth
    if is_logged_in?
      @session = session
      return true
    else
      redirect '/login'
      return false
    end 
  end
  
  def clear_session
    session.clear
  end

  def isAdmin!(team)
    unless Team.new(team).isAdmin? session[:username]
      throw(:halt, [401, "Not authorized\n"])
    end 
  end

  def isMember!(team)
    unless Team.new(team).isMember? session[:username]
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Pinch requires authentication")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    return true if is_logged_in? == true
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    if @auth.provided? && @auth.basic? && @auth.credentials && validate(@auth.credentials[0], @auth.credentials[1])
      session[:username] = @auth.username
    else
      return false
    end
  end

end

# shared to_hash function
def custom_to_hash(obj)
  # convert the object instance to a hash
  hash = {}
  obj.instance_variables.map do | s |
    # remove the @ symbol for attribute names
    if s.to_s.match(/^@/)
      k = s[1..-1].to_s
    else
      k = v.to_s
    end

    # set val to the value of the obj attr
    val = obj.instance_variable_get(s)

    # sometimes attributes are objects in themselves. to_hash them too
    if val.respond_to? :to_hash
      hash[k] = val.to_hash
    else
      if val.kind_of?(Array)
        tmpList = []
        val.each do | t |
          if t.respond_to? :to_hash
            tmpList << t.to_hash
          else
            tmpList << t
          end
        end
        hash[k] = tmpList
      else
        hash[k] = val
      end
    end
  end
  return hash
end

# shared to_json funciton
def custom_to_json(obj)
  return "#{JSON.pretty_generate(obj)}
"
end
