# Incident classes

class Incident
  attr_reader :team, :id, :createDate, :timeline

  def initialize(team=nil, id=nil)
    if team.nil?
      puts "cannot init incident"
      raise IncidentError, "Cannot initialize incident with no team specified", caller
    else
      @team = Team.new(team)
    end

    if id.nil?
      # no id specified, so creating one
      @createDate = Time.new.utc.to_f
      @id = Digest::MD5.hexdigest(@createDate.to_s)
      REDIS.set("#{@team.name}:#{@id}:createDate", @createDate)
      @team.populateTeamDetail
      firstEvent = Timeline::Event.new(@team.name, @id, { 'message' => 'Launched new pinch incident', 'severity' => "minor", 'author' => 'Pinch' })
      firstEvent.save
      @timeline = Timeline.new(@team.name, @id)
      @team.last_incident = @id
      @team.current_incident = @id
      @team.addIncident(@id)
    else
      if id == 'current'
        id = @team.current_incident
      elsif id == 'latest'
        id = @team.last_incident
      end
      puts "#{@team.name}:#{id}:createDate"
      if REDIS.exists("#{@team.name}:#{id}:createDate")
        @id = id
        @team = Team.new(team)
        @timeline = Timeline.new(@team.name, @id)
        @createDate = Time.at(REDIS.get("#{@team.name}:#{@id}:createDate").to_f)
      else
        puts "unknown incident id"
        raise IncidentError, "Unknown incident ID", caller
      end
    end
  end

  def delete
    @team.populateTeamDetail
    @team.removeIncident(@id)
    @team.save
    keys = REDIS.keys("#{@team.name}:#{@id}:*")
    keys.each do | k | 
      REDIS.del(k)
    end
  end

  def to_hash
    return custom_to_hash(self)
  end

  def to_json
    return custom_to_json(self.to_hash)
  end

end

class IncidentError < RuntimeError

end
