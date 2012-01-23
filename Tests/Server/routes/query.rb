get '/test/query' do
	Log.debug(params.inspect)
	ok(params)
end