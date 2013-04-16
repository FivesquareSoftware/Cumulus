include FileUtils


before '/test/download/massive' do
  mkdir_p('tmp')
  if !File.exists?('tmp/massive.png')
    Log.debug("Generating massive.png")
    File.open('tmp/massive.png','a+') do |file|
      (0..100).each do |i|
        file.write(File.read('resources/t_hero.png'))
      end
    end
  end
end


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

get '/test/stream/hero' do
	content_type('image/png')
	send_file('resources/t_hero.png', :filename => 'hero.png')
end

get '/test/download/hero' do
	content_type('image/png')
	headers('Content-Disposition' => 'attachment; filename="massive.png"')
	File.read('resources/t_hero.png')
end

get '/test/stream/massive' do
	content_type('image/png')
	send_file('tmp/massive.png', :filename => 'massive.png')
end

get '/test/download/massive' do
	content_type('image/png')
	headers('Content-Disposition' => 'attachment; filename="massive.png"')
	
	# send_file does not send content-length header if the file is over the buffer size which is bad bad for resumes
	#send_file('tmp/massive.png', :filename => 'massive.png')
	File.read('tmp/massive.png')
end

