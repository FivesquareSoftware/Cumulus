include FileUtils

put '/test/encoding' do
	ok()
end

get '/test/decoding/:format/content-type' do |format|
	bad_request('No format') and return unless format
	if /json/ =~ format
		respond(200, { :message => 'Hello World!' }, :json, 'application/json')
	elsif /xml/ =~ format
		respond(200, { :message => 'Hello World!' }, :xml, 'application/xml')
	elsif /text/ =~ format
		respond(200, 'Hello World!', :text, 'text/plain')
	elsif /image/ =~ format
		content_type('image/png')
		send_file('resources/t_hero.png', :filename => 'hero.png')
	else
		bad_request('Unknown Format')
	end	
end

get '/test/decoding/:format/wrong-content-type' do |format|
	bad_request('No format') and return unless format
	if /json/ =~ format
		respond(200, { :message => 'Hello World!' }, :json, 'magic/teapot')
	elsif /xml/ =~ format
		respond(200, { :message => 'Hello World!' }, :json, 'magic/teapot')
	elsif /text/ =~ format
		respond(200, 'Hello World!', :text, 'magic/teapot')
	elsif /image/ =~ format
	  content_type('magic/teapot')
		send_file('resources/t_hero.png', :filename => 'hero.png')
	else
		bad_request('Unknown Format')
	end	
end


