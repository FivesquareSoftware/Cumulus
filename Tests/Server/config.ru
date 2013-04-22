require 'rack'
use Rack::ContentLength

require 'main'
run Sinatra::Application
