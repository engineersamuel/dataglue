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

  def self.mysql_query(ref, sql, single=false)
    host = DataGlueSettings::mysql_refs[ref]['host']
    user = DataGlueSettings::mysql_refs[ref]['user']
    pass = Base64.decode64(DataGlueSettings::mysql_refs[ref]['pass']).strip()
    db = DataGlueSettings::mysql_refs[ref]['db']
    client = Mysql2::Client.new(:host => host, :username => user, :password => pass, :database => db)
    client.query(sql)
  end

  def self.query(ref, sql, single=false)
    type = DataGlueSettings::mysql_refs[ref]['type']
    if type == 'mysql'
      return self.mysql_query(ref, sql, single)
    end
  end

end
