require 'json'

module Rack
	
	class JSONOutput

		def initialize(app)
			@app = app
		end
		
		def call(env)
			begin
				status, headers, body = @app.call(env)
				Log.debug("body: #{body.inspect}")
				Log.debug("headers: #{headers.inspect}")
				# body = JSON.generate(body) if json_response?(headers)
				[status, headers, body]
			rescue Exception => e	
				Log.fatal(e)
				e.backtrace.each{|line| Log.fatal(line)}
			end
		end

		def json_response?(headers)
			headers['Content-Type'] == 'application/json' 
		end

	end

end

use Rack::ContentLength
