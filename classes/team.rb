# Team Classes

class Team
  attr_reader :current_incident, :last_incident, :createDate
  attr_accessor :name, :incidents, :members, :admins, :requests

  @@mongo = MONGO.collection("teams")
 
  def initialize(name=nil)
    if name.nil?
      @name = name
      @last_incident = 0 
      @current_incident = 0 
      @createDate = Time.now.utc.to_f
      @incident = []
      @admins = []
      @members = []
      @requests = []
    else
      if REDIS.exists("#{name}:createDate")
        @name = name
        @last_incident = REDIS.get("#{@name}:last")
        @current_incident = REDIS.get("#{@name}:current")
        @createDate = Time.at(REDIS.get("#{@name}:createDate").to_f).to_f
      else
        raise TeamError, "Team does not exist", caller
      end
    end
  end

  def last_incident=(newIncident)
    @last_incident = newIncident
    REDIS.set("#{@name}:last", newIncident)
  end

  def current_incident=(newIncident)
    @current_incident = newIncident
    REDIS.set("#{@name}:current", newIncident)
  end

  def addIncident(id)
    @incidents << id
    self.last_incident=id
  end

  def removeIncident(id)
    @incidents.delete(id)
    if id == self.last_incident
      self.last_incident=@incident[-1]
    end
    if id == self.current_incident
      self.current_incident=0
    end
  end

  def populateTeamDetail
    t = @@mongo.find('name' => @name).to_a[0]
    @incidents = t['incidents']
    @admins = t['admins']
    @members = t['members']
    @requests = t['requests']
  end

  def save
    @@mongo.update( { 'name' => @name } , { 'name' => @name, 'incidents' => @incidents, 'admins' => @admins, 'members' => @members, 'requests' => @requests }, :upsert => true)
    REDIS.set("#{@name}:createDate", @createDate)
  end

  def delete
    keys = REDIS.keys("#{@name}:*")
    keys.each do | k | 
      REDIS.del(k)
    end
    @@mongo.remove({'name' => @name})
  end

  def isAdmin?(user)
    if @admins.nil?
      self.populateTeamDetail  
    end
    if @admins.include? user
      return true
    else
      return false
    end
  end

  def isMember?(user)
    return true if self.isAdmin?(user)
    if @members.nil?
      self.populateTeamDetail  
    end 
    if @members.include?(user)
      return true
    else
      return false
    end
  end

  def exists?
    if REDIS.exists("#{@name}:createDate")
      return true
    else
      return false
    end
  end

  def query(query)
    hashes = @@mongo.find(query)
    teams = []
    hashes.each do | team |
      t = Team.initialize(team['name'])
      t.populateTeamDetail
      teams << t
    end
    return teams
  end

  def to_hash
    return custom_to_hash(self)
  end

  def to_json
    return custom_to_json(self.to_hash)
  end  

end

class TeamError < RuntimeError

end
