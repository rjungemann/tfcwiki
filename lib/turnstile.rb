require 'moneta'
require 'digest/sha2'
require 'uuid'

class Generate
  @@uuid = UUID.new
  
  def self.salt
    [Array.new(6) { rand(256).chr }.join].pack('m').chomp
  end
  
  def self.hash password, salt
    Digest::SHA256.hexdigest password + salt
  end
  
  def self.uuid
    @@uuid.generate
  end
end

class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

module Turnstile
  module Model
    class Turnstile
      attr_accessor :realms, :users, :roles

      def initialize store
        @store = store

        @realms = Realms.new store
        @users = Users.new store
        @roles = Roles.new store
      end
    end

    class Realms
      def initialize store
        @store = store
        @store["realms"] ||= []
      end

      def all; @store["realms"] end

      def find realm
        raise "Realm must be specified." if realm.blank?

        @store["realm-#{realm}"]
      end

      def create realm
        raise "Realm must be specified." if realm.blank?
        raise "Realm already exists." unless @store["realm-#{realm}"].blank?
        
        @store["realms"] = @store["realms"] << realm
        @store["realm-#{realm}"] = { :roles => [], :created_on => Time.now }
      end

      def destroy realm
        raise "Realm must be specified." if realm.blank?
        raise "Realm doesn't exist." if @store["realm-#{realm}"].blank?

        @store["realms"] = @store["realms"].reject { |r| r == realm }
        @store["realm-#{realm}"] = nil
      end

      def roles realm
        raise "Realm must be specified." if realm.blank?
        raise "Realm doesn't exist." if @store["realm-#{realm}"].blank?

        @store["realm-#{realm}"][:roles]
      end

      def add_role realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Realm must be specified." if realm.blank?

        r = @store["realm-#{realm}"]

        raise "Realm doesn't exist." if r.blank?
        raise "Role doesn't exist." unless @store["roles"].include? role
        raise "Realm already has role." if r[:roles].include? role

        r[:roles] << role
        @store["realm-#{realm}"] = r
      end

      def remove_role realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Realm must be specified." if realm.blank?

        r = @store["realm-#{realm}"]

        raise "Realm doesn't exist." if r.blank?
        raise "Role doesn't exist." unless @store["roles"].include? role
        raise "Realm already has role." if r[:roles].include? role

        r[:roles] = r[:roles].reject { |r| r == role }
        @store["realm-#{realm}"] = r
      end

      def has_role? realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Realm must be specified." if realm.blank?

        r = @store["realm-#{realm}"]

        raise "Realm doesn't exist." if r.blank?

        r[:roles].include? role
      end

      alias :exists? :find
    end

    class Users
      def initialize store
        @store = store
        @store["users"] ||= []
        @store["uuids"] ||= {}
      end

      def all; @store["users"] end

      def find name
        raise "Name must not be blank." if name.blank?

        @store["user-#{name}"]
      end

      def create name
        raise "Name must not be blank." if name.blank?
        raise "Name must be unique." unless @store["user-#{name}"].blank?

        user = { :name => name, :realms => {}, :created_on => Time.now }
        @store["user-#{name}"] = user
        @store["users"] = @store["users"] << name
        user
      end

      def destroy name
        raise "Name must not be blank." if name.blank?
        raise "User doesn't exist." if @store["user-#{name}"].blank?

        @store["user-#{name}"] = nil
        @store["users"] = @store["users"].reject { |u| u[:name] == name }
      end

      def realms name
        raise "Name must not be blank." if name.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?

        user[:realms]
      end

      def add_realm realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User is already part of realm." unless user[:realms][realm].blank?
        
        salt = Generate.salt
        hash = Generate.hash password, salt
        
        user[:realms][realm] = { :roles => [], :salt => salt, :hash => hash }
        @store["user-#{name}"] = user
      end
      
      def remove_realm realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?
        
        user[:realms][realm] = nil
        @store["user-#{name}"] = user
      end

      def in_realm? realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?

        user[:realms][realm]
      end

      def change_password realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?
        
        salt = Generate.salt
        hash = Generate.hash password, salt
        
        user[:realms][realm][:salt] = salt
        user[:realms][realm][:hash] = hash
        @store["user-#{name}"] = user
      end
      
      def check_password realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?
        
        user[:realms][realm][:hash] == Generate.hash(password, user[:realms][realm][:salt])
      end

      def roles realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?

        user[:realms][realm][:roles]
      end

      def authorized? realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?

        user[:realms][realm][:roles].include? role
      end
      
      def add_role realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "Role doesn't exist" unless @store["roles"].include? role
        raise "User isn't part of realm." if user[:realms][realm].blank?
        raise "User already has role." if user[:realms][realm][:roles].include? role
        
        user[:realms][realm][:roles] << role
        @store["user-#{name}"] = user
      end
      
      def remove_role realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = @store["user-#{name}"]

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "Role doesn't exist" unless @store["roles"].include? role
        raise "User isn't part of realm." if user[:realms][realm].blank?
        raise "User doesn't perform this role." unless user[:realms][realm][:roles].include role
        
        user[:realms][realm][:roles] = user[:realms][realm][:roles].reject { |ro| ro == role }
        @store["user-#{name}"] = user
      end

      def signin realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?
        raise "Password is incorrect." unless user[:realms][realm][:hash] == Generate.hash(password, user[:realms][realm][:salt])
        
        uuids = @store["uuids"]
        uuid = Generate.uuid
        uuids[uuid] = { :name => name, :realm => realm }
        @store["uuids"] = uuids
        
        user[:realms][realm][:uuid] = uuid
        
        @store["user-#{user}"] = user
        
        uuid
      end
      
      def signout realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm must not be blank." if realm.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        
        user = @store["user-#{name}"]
        uuid = user[:realms][realm][:uuid]
        
        raise "User doesn't exist." if user.blank?
        raise "User isn't part of realm." if user[:realms][realm].blank?
        raise "User isn't signed in." if uuid.blank?
        
        uuids = @store["uuids"]
        uuids.delete uuid
        @store["uuids"] = uuids
        
        user[:realms][realm][:uuid] = nil
        @store["user-#{user}"] = user
        
        nil
      end
      
      def signedin? realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        
        user = @store["user-#{name}"]
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store["realms"].include? realm
        raise "User isn't part of realm." if user[:realms][realm].blank?
        
        user[:realms][realm][:uuid]
      end
      
      def from_uuid uuid
        raise "uuid must not be blank." if uuid.blank?
        
        @store["uuids"][uuid]
      end

      alias :exists? :find
      alias :has_right? :authorized?
      alias :set_uuit :signin
      alias :uuid :signedin?
    end

    class Roles
      def initialize store
        @store = store
        @store["roles"] ||= []
      end

      def all; @store["roles"] end

      def find role
        raise "Role name must not be blank." if role.blank?

        @store["role-#{role}"]
      end

      def create role, *rights
        raise "Role name must not be blank." if role.blank?

        r = @store["role-#{role}"]

        raise "Role already exists." unless r.blank?

        r = { :rights => rights, :created_on => Time.now }
        @store["role-#{role}"] = r
        @store["roles"] = @store["roles"] << role
      end

      def destroy role
        raise "Role name must not be blank." if role.blank?
        raise "Role doesn't exist." if @store["role-#{role}"].blank?

        @store["roles"] = @store["roles"].reject { |r| r == role }
        @store["role-#{role}"] = nil
      end

      def rights role
        raise "Role name must not be blank." if role.blank?
        raise "Role doesn't exist." if @store["role-#{role}"].blank?

        @store["role-#{role}"][:rights]
      end

      def has_right? role, right
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        raise "Role doesn't exist." if @store["role-#{role}"].blank?

        @store["role-#{role}"][:rights].include? right
      end

      def add_right role, right
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        raise "Role doesn't exist." if @store["role-#{role}"].blank?

        r = @store["role-#{role}"]

        raise "Right already exists." if r[:rights].include? right

        r[:rights] << right
        @store["role-#{role}"] = r
      end

      def remove_right role, right
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        raise "Role doesn't exist." if @store["role-#{role}"].blank?

        r = @store["role-#{role}"]

        raise "Right doesn't exist." unless r[:rights].include? right

        r[:rights] = r[:rights].reject { |ri| right == ri }
        @store["role-#{role}"] = r
      end

      alias :exists? :find
    end
  end
end