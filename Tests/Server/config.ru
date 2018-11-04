require 'rack'
use Rack::ContentLength

require_relative 'main'
run Sinatra::Application
