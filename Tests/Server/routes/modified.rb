get '/test/last-modified' do
	headers('Last-Modified' => Time.now.httpdate)
	ok(item)
end

get '/test/no-last-modified' do
	ok(item)
end

get '/test/if-modified/not' do
	if_modified = request.env['HTTP_IF_MODIFIED_SINCE']
	if if_modified
		respond(304,{})
	else
		headers('Last-Modified' => Time.now.httpdate)
		ok(item)
	end
end

get '/test/if-modified/is' do
	if_modified = request.env['HTTP_IF_MODIFIED_SINCE']
	if if_modified
		ok(item)
	else
		headers('Last-Modified' => Time.now.httpdate)
		ok(item)
	end
end
