include FileUtils

rm_rf(File.join('public','test/benchmarks'))

before '/test/benchmarks/*' do
  if request.request_method == 'GET'
  	@filepath = File.join('public',request.path_info[1,request.path_info.length])
  	mkdir_p(File.dirname(@filepath))
  	Log.debug("Generating #{@filepath}")
  end
end


get '/test/benchmarks/small-resource.json' do
  result =  item.json_proxy.to_json
	File.open(@filepath, 'w+') { |file| file.write(result) }
	ok(result)
end

post '/test/benchmarks/small-resource.json' do
	ok()
end

get '/test/benchmarks/large-resource.json' do 
  result = large_list.json_proxy.to_json
	File.open(@filepath, 'w+') { |file| file.write(result) }
	ok(result)
end

post '/test/benchmarks/large-resource.json' do 
	ok()
end

get '/test/benchmarks/complicated-resource.json' do
  complicated_list.json_proxy.to_json(:indent => "\t", :object_nl => "\n")
	File.open(@filepath, 'w+') { |file| file.write(result) }
	ok(result)
end

post '/test/benchmarks/complicated-resource.json' do
	ok()
end

get '/test/benchmarks/small-file.png' do
	copy('resources/t_hero.png',@filepath)
	send_file(@filepath)
end

put '/test/benchmarks/small-file.png' do
	ok()
end

get '/test/benchmarks/large-file.png' do
	copy('resources/hs-2006-01-c-full_tif.png',@filepath)
	send_file(@filepath)
end

put '/test/benchmarks/large-file.png' do
	ok()
end

