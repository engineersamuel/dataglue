require 'mysql2'
require_relative '../utils/settings'
require_relative '../db/database_manager_module'

include DatabaseManagerModule

results = DatabaseManagerModule::query('kcsdw', 'SHOW COLUMNS FROM kcsdw.bugs')
#client = Mysql2::Client.new(:host => 'db.dev.gss.redhat.com', :username => 'kcsdw', :password => 'kcsdw', :database => 'kcsdw')
#results = client.query('SELECT * FROM sfdc_users LIMIT 50')

results.each do |row|
  # conveniently, row is a hash
  # the keys are the fields, as you'd expect
  # the values are pre-built ruby primitives mapped from their corresponding field types in MySQL
  # Here's an otter: http://farm1.static.flickr.com/130/398077070_b8795d0ef3_b.jpg
  p row
end


