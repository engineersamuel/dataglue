require 'rubygems'
require 'mysql2'
require_relative '../utils/settings'


module DatabaseManagerModule
  #attr_reader :mysql_conns

  #def self.included(base)
  #  @client = MongoClient.new('localhost', 27017, :pool_size => 1)
  #end

  #def self.mysql_conns
  #  @mysql_conns
  #end

  def self.mysql_query(name, sql, single=false)
    host = DataGlueSettings::mysql_refs[name]['host']
    user = DataGlueSettings::mysql_refs[name]['user']
    pass = Base64.decode64(DataGlueSettings::mysql_refs[name]['pass']).strip()
    db = DataGlueSettings::mysql_refs[name]['db']
    client = Mysql2::Client.new(:host => host, :username => user, :password => pass, :database => db)
    client.query(sql)
  end

end
