module Rack
	class ExceptionHandler
	
		def initialize(app)
			@app = app
		end

		def call(env)
			error = nil
			status,headers,body = 
			begin
				@app.call(env)
			rescue Exception => e
				error = e
			end
			if error
				status = 500
				body = error.json_proxy.to_json
				headers = {'Content-Type' => 'application/json'}
				send_notification(error)
			end
			[status,headers,body]
		end
		
		def send_notification(exception)
			# TODO: hook this up to some real notifications
			# Log for now ..
			Log.fatal("Uncaught exception: #{exception.class.name} (#{exception.message})")
			exception.backtrace.each{|line| Log.fatal(line)}
		end
	
	end
end
