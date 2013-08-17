require 'yaml'
require 'base64'

module DataGlueSettings
  attr_reader :config, :mysql_refs

  def self.config
    if @config.nil?
      @config = YAML.load_file(File.expand_path('~/.dataglue-settings.yml'))
    end
    @config
  end

  def self.mysql_refs
    if @mysql_refs.nil?
      @mysql_refs = Hash[DataGlueSettings::config['mysql_refs'].map { |i| [i['name'], i] }] || {}
    end
    @mysql_refs
  end
end
