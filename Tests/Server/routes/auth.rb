get '/test/protected' do
	protected!
	ok(item)
end