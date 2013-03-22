# Severity class

class Severity
    
    @@major = 1
    @@minor = 2
    @@atomic = 3

    def initialize(val=nil)
        @val = @@atomic
        self.val = val unless val.nil?
    end

    def val=(newVal)
        if newVal == 'M' || newVal.to_s.downcase == 'maj' || newVal.to_s.downcase == 'major' || newVal == @@major
          @val = @@major
        elsif newVal == 'm' || newVal.to_s.downcase == 'min' || newVal.to_s.downcase == 'minor' || newVal == @@minor
          @val = @@minor 
        elsif newVal.to_s.downcase == 'a' || newVal.to_s.downcase == 'atm' || newVal.to_s.downcase == 'atomic' || newVal == @@atomic
          @val = @@atomic
        else
          raise SeverityError, "Invalid severity value (#{newVal})", caller
        end
    end

    def abbr
        case @val
            when @@major
                return 'M'
            when @@minor
                return 'm'
            when @@atomic
                return 'a'
            else
                raise SeverityError, "No abbreviations available", caller
            end
    end

    def short
        case @val
            when @@major
                return 'maj' 
            when @@minor
                return 'min' 
            when @@atomic
                return 'atm'
            else
              raise SeverityError, "No short form available", caller
            end
    end

    def long
        case @val
            when @@major
                return 'major' 
            when @@minor
                return 'minor' 
            when @@atomic
                return 'atomic'
            else
              raise SeverityError, "No long form available", caller 
            end
    end

    def isMajor
        if @val == @@major
            return true
        else
            return false
        end
    end

    def isMinor
        if @val == @@major
            return true
        else
            return false
        end
    end

    def isAtomic
        if @val == @@major
            return true
        else
            return false
        end
    end

    def to_hash
      return self.long
    end

end

class SeverityError < RuntimeError

end
