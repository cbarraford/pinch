# Timeline classes

class Timeline

  attr_reader :events

  def initialize(team=nil, id=nil)
    if team.nil? and id.nil?
      raise TimelineError, "Need to initialize a timeline with a team and incident id", caller
    else
      @team = Team.new(team)
      @id = id
      if id == 'current'
        @id = @team.current_incident
      elsif id == 'latest'
        @id = @team.last_incident
      end 
      @events = []
    end
    
    rawevents = REDIS.zrange("#{@team.name}:#{@id}:events", 0, -1)
    if rawevents.is_a? Array
      rawevents.each do | event | 
        @events << Timeline::Event.new(@team.name, @id, event)
      end
    else
      @events << Timeline::Event.new(@team.name, @id, rawevents)
    end
  end

  def saveAll
    @events.each do | event |
      event.save(event.timestamp)
    end
  end

  def to_hash
    return custom_to_hash(self)
  end

  def to_json
    return custom_to_json(self.to_hash)
  end


  class Event
    attr_accessor :author, :message, :severity, :silent

    def initialize(team=nil,incident_id=nil,data=nil)
      if team.nil? or incident_id.nil?
        raise TimelineEventError, "Must initialize timeline event with team name and incident id", caller
      else
        @team = Team.new(team)
        @incident_id = incident_id
        if incident_id == 'current'
          @incident_id = @team.current_incident
        elsif incident_id == 'latest'
          @incident_id = @team.last_incident
        end
      end

      # starting fresh, initiating new timeline event object, default values
      @severity = Severity.new
      @author = 'Unknown'
      @createDate = @timestamp = Time.new.utc.to_f
      @message = 'bueller?....bueller?'
      @silent = false

      if data.is_a? Integer or data.is_a? Float
        result = REDIS.zrangebyscore("#{@team.name}:#{@incident_id}:events", data.to_s, data.to_s)
        if result.nil? or result.empty?
          raise TimelineEventError, "Cannot find specified timeline event", caller
        elsif result.length > 1
          # expected one timeline event, but got more, oops
          raise TimelineEventError, "Timeline Event collision, found #{result.length} events at #{data}", caller
        else
          event = JSON.parse(result[0])
        end
      elsif data.is_a? String
        event = JSON.parse(data)
      elsif data.is_a? Hash
        event = data
      elsif data.nil?
        return
      else
        raise TimelineEventError, "Must pass valid json string, hash, or timestamp to init a timeline event (#{data.class()})", caller
      end
      event.each_pair do |name, value|
        self.instance_variable_set("@"+name, value) if name != 'team' and name != 'incident_id'
      end
      @severity = Severity.new(event['severity']) if ! event['serverity'].nil?
    end

    def timestamp=(newTimestamp)
      # we need to save the old timestamp so we can later find the event in the db
      @timestampCHG = @timestamp
      @timestamp = newTimestamp
    end

    def severity=(newSev)
      @severity.val = newSev
    end

    def sev
      @severity.long
    end

    def save(score=nil)
      if score.nil?
        #create val to increment timestamp if needed, when its timestamp already in use as UID
        incr = ('0.' + ('0' * (@timestamp.to_s.split('.')[-1].length)) + '1').to_f
  
        foundSlot = false
        (0..1000).each do |n|
          ts = @timestamp.to_f + (incr * n)
          if REDIS.zrangebyscore("#{@team.name}:#{@incident_id}:events", ts, ts).empty?
            REDIS.multi do
              @timestamp = ts
              foundSlot = true
              if ! score.nil?
                # if score is given, we're updating an existing timeline event, so we need to delete it and readd
                REDIS.ZREMRANGEBYSCORE("#{@team.name}:#{@incident_id}:events", score, score)
              end
              REDIS.zadd("#{@team.name}:#{@incident_id}:events", ts, self.to_hash.to_json)
            end
            break
          end
        end
        if foundSlot == false
          raise TimelineEventError, "Unable to find open slot to put timeline event", caller
        end
      else
        REDIS.multi do
          # delete member if exists before adding it again
          REDIS.ZREMRANGEBYSCORE("#{@team.name}:#{@incident_id}:events", score.to_s, score.to_s)
          REDIS.zadd("#{@team.name}:#{@incident_id}:events", @timestamp.to_s, self.to_hash.to_json)
        end
      end
    end

    def delete()
      REDIS.ZREMRANGEBYSCORE("#{@team.name}:#{@incident_id}:events", @timestamp.to_s, @timestamp.to_s)
    end

    def to_hash
      return custom_to_hash(self)
    end

    def to_json
      return custom_to_json(self.to_hash)
    end

  end
end

class TimelineEventError < RuntimeError; end

class TimelineError < RuntimeError; end
