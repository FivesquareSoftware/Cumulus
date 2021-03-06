require 'rubygems'
require 'ruby-debug'

require 'bundler/setup'

require 'sinatra'
require 'dependencies'
require 'requires'
require 'configuration'



use Rack::JSONInput
#use Rack::JSONOutput # Sinatra doesn't like anything but a string going out, so all json conversion now happens internally


Log.info("Started service with #{Sinatra::Application.environment} environment")

load 'routes/get.rb'
load 'routes/post.rb'
load 'routes/put.rb'
load 'routes/delete.rb'
load 'routes/head.rb'
load 'routes/auth.rb'
load 'routes/response_codes.rb'
load 'routes/coding.rb'
load 'routes/files.rb'
load 'routes/benchmarks.rb'
load 'routes/query.rb'
load 'routes/modified.rb'

head '/index' do
	ok('OK')
end

get '/index' do
	ok('OK')
end

get '/index/slow' do
	sleep(1)
	ok('OK')
end

get '/slow' do
	sleep(1)
	ok('OK')
end

get '/superslow' do
	sleep(5)
	ok('OK')
end

get '/crazyslow' do
	sleep(20)
	ok('OK')
end

put '/index' do
	ok('OK')
end

post '/index' do
	ok('OK')
end

delete '/index' do
	ok('OK')
end

put '/echo' do
	respond(200,{ :message => params[:message] })
end

get '/modified' do
	last_modified(Time.now)
	ok('OK')
end
