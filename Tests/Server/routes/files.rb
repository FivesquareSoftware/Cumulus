include FileUtils

put '/test/upload/hero' do
  	mkdir_p('tmp')
  	File.open('tmp/t_hero.png', 'w+') do |file|
  		file.write(request.body.read)
  	end
	
  	success = compare_file('resources/t_hero.png','tmp/t_hero.png')
  	if success
  		ok()
	else
  		bad_request("Files were not equal")
  	end	
end

get '/test/download/hero' do
	content_type('image/png')
	send_file('resources/t_hero.png', :filename => 'hero.png')
end

