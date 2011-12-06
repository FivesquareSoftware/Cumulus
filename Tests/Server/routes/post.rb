post '/test/post/item' do
	ok(params)
end

post '/test/post/list' do
	ok(params['list'])
end

post '/test/post/large-list' do
	ok(params['list'])
end

post '/test/post/complicated-list' do
	ok(params['list'])
end

