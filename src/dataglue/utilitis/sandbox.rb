require 'mysql2'
require 'active_support/core_ext/hash'
require_relative '../utils/settings'
require_relative '../db/database_manager_module'

a = {
    'dbReferences' => {
        "kcsdw_kcsdw_jjaggars_omniture_processed_files" => {
            'fieldA' => 1,
            'fields' => [
              'a' => 1,
              'b' => 2,
              '$$hashKey' => 3
            ]
        }
    }
}
a['dbReferences'].each do |k, v|
  ap "k: #{k}, v: #{v}"
  v['fields'].each {|f| f.except!('$$hashKey')}
end

ap a

#include DatabaseManagerModule
#
#results = DatabaseManagerModule::query('kcsdw', 'SHOW COLUMNS FROM kcsdw.bugs')
##client = Mysql2::Client.new(:host => 'db.dev.gss.redhat.com', :username => 'kcsdw', :password => 'kcsdw', :database => 'kcsdw')
##results = client.query('SELECT * FROM sfdc_users LIMIT 50')
#
#results.each do |row|
#  # conveniently, row is a hash
#  # the keys are the fields, as you'd expect
#  # the values are pre-built ruby primitives mapped from their corresponding field types in MySQL
#  # Here's an otter: http://farm1.static.flickr.com/130/398077070_b8795d0ef3_b.jpg
#  p row
#end


