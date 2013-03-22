# User Class

class User
  attr_accessor :name, :email, :username, :memberOf, :adminOf, :verified, :password

  @@mongo = MONGO.collection("users")

  def initialize(username=nil)
    if username.nil?
      @createDate = Time.now.utc.to_f
      @name = @email = @username = @password = nil
      @adminOf = @memberOf = []
      @verified = true
    else
      rawdata = @@mongo.find('username' => username).to_a
      if rawdata.length == 0
        raise UserError, "User not found", caller
      else
        user = rawdata[0]
        user.each_pair do |name, value|
          self.instance_variable_set('@'+name, value)
        end
        @adminOf = MONGO.collection("teams").find({'admins' => @username}).to_a
        @memberOf = MONGO.collection("teams").find({'members' => @username}).to_a
      end
    end
  end

  def save()
    if self.exist?
      raise UserError, "Cannot save new user, username already in use", caller
    else
      @@mongo.insert( self.to_hash )
      return true
    end
  end

  def exist?
    if @@mongo.find_one('username' => @username).nil?
      return false
    else
      return true
    end
  end

  def update()
    @@mongo.update( { 'username' => @username }, self.to_hash )
  end

  def delete()
    @@mongo.remove( 'username' => @username )
  end

  def to_public_hash
    h = custom_to_hash(self)
    h.delete('password')
    return h
  end

  def to_public_json
    return custom_to_json(self.to_public_hash)
  end

  def to_hash
    return custom_to_hash(self)
  end

  def to_json
    return custom_to_json(self.to_hash)
  end

end

class UserError < RuntimeError; end

require 'digest/sha2'

# This module contains functions for hashing and storing passwords
module Password

  # Generates a new salt and rehashes the password
  def Password.update(password)
    salt = self.salt
    hash = self.hash(password,salt)
    self.store(hash, salt)
  end

  # Checks the password against the stored password
  def Password.check(password, store)
    hash = self.get_hash(store)
    salt = self.get_salt(store)
    if self.hash(password,salt) == hash
      true

    else
      false
    end
  end

  protected

  # Generates a psuedo-random 64 character string

  def Password.salt
    salt = ''
    64.times { salt << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    salt
  end

  # Generates a 128 character hash
  def Password.hash(password,salt)
    Digest::SHA512.hexdigest("#{password}:#{salt}")
  end

  # Mixes the hash and salt together for storage
  def Password.store(hash, salt)
    hash + salt
  end

  # Gets the hash from a stored password
  def Password.get_hash(store)
    store[0..127]
  end

  # Gets the salt from a stored password
  def Password.get_salt(store)
    store[128..192]
  end
end

