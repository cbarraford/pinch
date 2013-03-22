# Tasklist classes

class Tasklist

  def initialize(team=nil, id=nil)
    if team.nil? and id.nil?
      raise TasklistError, "Need to initialize a tasklist with a team and incident id", caller
    else
      @team = Team.new(team)
      @id = id
      if id == 'current'
        @id = @team.current_incident
      elsif id == 'latest'
        @id = @team.last_incident
      end 
      @tasks = []
    end
    
    rawtasks = REDIS.zrange("#{@team.name}:#{@id}:tasks", 0, -1)
    if rawtasks.is_a? Array
      rawtasks.each do | task | 
        @tasks << Tasklist::Item.new(@team.name, @id, task)
      end
    else
      @tasks << Tasklist::Item.new(@team.name, @id, rawtasks)
    end
  end

  def saveAll
    @tasks.each do | task |
      task.save()
    end
  end

  def to_hash
    return custom_to_hash(self)
  end

  def to_json
    return custom_to_json(self.to_hash)
  end

  class Item
    attr_accessor :description, :author, :owner, :state, :silent

    def initialize(team=nil,incident_id=nil,data=nil)
      if team.nil? or incident_id.nil?
        raise TasklistItemError, "Must initialize tasklist item with team name and incident id", caller
      else
        @team = Team.new(team)
        @incident_id = incident_id
        if incident_id == 'current'
          @incident_id = @team.current_incident
        elsif incident_id == 'latest'
          @incident_id = @team.last_incident
        end
      end

      # starting fresh, initiating new tasklist item object, default values
      @severity = Severity.new
      @author = 'Unknown'
      @owner = 'None'
      @createDate = @timestamp = Time.new.utc.to_f
      @description = 'bueller?....bueller?'
      @id = nil
      @state = "open"

      if data.is_a? Integer or data.is_a? Float
        result = REDIS.zrangebyscore("#{@team.name}:#{@incident_id}:tasks", data.to_s, data.to_s)
        if result.nil? or result.empty?
          raise TasklistItemError, "Cannot find specified tasklist item", caller
        elsif result.length > 1
          # expected one tasklist item, but got more, oops
          raise TasklistItemError, "Tasklist item collision, found #{result.length} tasks at #{data}", caller
        else
          task = JSON.parse(result[0])
        end
      elsif data.is_a? String
        task = JSON.parse(data)
      elsif data.is_a? Hash
        task = data
      elsif data.nil?
        return
      else
        raise TasklistItemError, "Must pass valid json string, hash, or id to init a tasklist item (#{data.class()})", caller
      end
      task.each_pair do |name, value|
        self.instance_variable_set("@"+name, value) if name != 'team' and name != 'incident_id'
      end
      @severity = Severity.new(task['severity']) if ! task['serverity'].nil?
    end

    def severity=(newSev)
      @severity.val = newSev
    end

    def sev
      @severity.long
    end

    def save(id=nil)
      if id.nil?
        id = REDIS.incr("#{@team.name}:#{@incident_id}:nxt_id")
        @id = id
      end
      REDIS.multi do
        # delete member if exists before adding it again
        REDIS.ZREMRANGEBYSCORE("#{@team.name}:#{@incident_id}:tasks", id.to_s, id.to_s)
        REDIS.zadd("#{@team.name}:#{@incident_id}:tasks", id, self.to_hash.to_json)
      end
    end

    def delete()
      REDIS.ZREMRANGEBYSCORE("#{@team.name}:#{@incident_id}:tasks", @id, @id)
    end

    def to_hash
      return custom_to_hash(self)
    end

    def to_json
      return custom_to_json(self.to_hash)
    end

  end
end

class TasklistItemError < RuntimeError; end

class TasklistError < RuntimeError; end
