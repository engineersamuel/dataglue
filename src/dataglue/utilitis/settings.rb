require 'yaml'
require 'base64'

module DataGlueSettings
  attr_reader :config, :mysql_refs, :db_refs, :master_ref, :environment, :delim

  #http://unicode-table.com/en/search/?q=%E2%A6%80
  def self.delim
    #'\u2980'
    '_'
  end

  def self.config
    if @config.nil?
      if ENV['OPENSHIFT_DATA_DIR']
        #@config = YAML.load_file(File.expand_path('$OPENSHIFT_DATA_DIR/.dataglue-settings.yml'))
        @config = YAML.load_file(File.join(ENV['OPENSHIFT_DATA_DIR'], '.dataglue-settings.yml'))
      else
        @config = YAML.load_file(File.expand_path('~/.dataglue-settings.yml'))
      end
    end
    @config
  end

  # Set the environment depending first by the data glue settings, otherwise assing prod if on Openshift
  def self.environment
    if self.config['env'].nil?
      return ENV['OPENSHIFT_DATA_DIR'].nil? ? 'dev' : 'prod'
    end
    return self.config['env']
  end

  def self.db_refs
    if @db_refs.nil?
      @db_refs = Hash[DataGlueSettings::config['db_refs'].map { |i| [i['name'], i] }] || {}
    end
    @db_refs
  end

  def self.mysql_refs
    if @mysql_refs.nil?
      @mysql_refs = Hash[DataGlueSettings::config['db_refs'].select{ |i| i['type'] == 'mysql'}.map { |i| [i['name'], i] }] || {}
    end
    @mysql_refs
  end

  # Points to the master database for dataglue, which will be mongo
  def self.master_ref
    if @master_ref.nil?
      @master_ref = DataGlueSettings::config['master_database'][self.environment] || {}
    end
    @master_ref
  end
end
