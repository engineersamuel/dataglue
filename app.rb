# require rubygems and sinatra so you can run this application locally with ruby app.rb
require 'rubygems'
require 'sinatra'

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/agent' do
  "you're using #{request.user_agent}"
end