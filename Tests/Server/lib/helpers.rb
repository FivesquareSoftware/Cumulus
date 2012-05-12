
helpers do

	# Responders
	
	def respond(status,object,format = :json,content_type = 'application/json')
		content_type(content_type)
		status(status)
		if format == :json
			object.json_proxy.to_json
		elsif format == :plist
			content_type(:xml)
			object.to_plist
		elsif format == :xml
			object.to_xml
		elsif format == :text
			object.to_s
		end
	end
	
	def ok(body={})
		respond(200,body)
	end
	
	def created(body={})
		respond(201,body)
	end
	
	def bad_request(body={})
		respond(400,body)
	end
	
	def unauthorized(body={})
		response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
		respond(401, body)
	end
	
	def forbidden(body={})
		respond(403,body)
	end

	def not_found(body={})
		respond(404,body)
	end 

	def unprocessable_entity(body={})
		respond(422,body)
	end
	
	def server_error(body={})
		respond(500,body)
	end
	
	
	# Auth
	
	def protected!
		# response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth") and
		# throw(:halt, [401, "Not authorized\n"]) and
		# return unless authorized?
		halt(unauthorized('Not Authorized')) unless authorized?
	end

	def authorized?
		@auth ||=	 Rack::Auth::Basic::Request.new(request.env)
		@auth.provided? && @auth.basic? && @auth.credentials && (@auth.credentials == ['test', 'test'] || @auth.credentials == ['bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1', 'bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1'])
	end

	# Fixtures
	
	def item
		if @item == nil
			@item = Plist.parse_xml('resources/Item.plist')
		end
		@item
	end
	
	def list(count=5)	
		(1..count).collect { self.item }
	end

	def large_list	
		list(10000)
	end
	
	def complicated_list	
		deep_item = item.merge( { 'object' => item.merge( { 'object' => item.merge( { 'object' => item.merge( { 'object' => item } ) } ) } ) } )
    @complicated_list = (0..99).collect { deep_item }
	end
	

end