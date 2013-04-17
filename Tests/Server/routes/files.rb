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
	filename = 'resources/hs-2006-01-c-full_tif.png'
	range = request.env['HTTP_RANGE']
	Log.debug("range: #{range}")
	start_at = 0
	end_at = File.size(filename)
	if range && range =~ /bytes=(\d+)-(\d+)?/
		start_at = $~.captures[0]
	end
	length = end_at-start_at
	Log.debug("start_at: #{start_at}")
	Log.debug("end_at: #{end_at}")

	
	content_type('image/png')
	headers('Content-Disposition' => 'attachment; filename="massive.png"')
	
	# send_file does not send content-length header if the file is over the buffer size which is bad bad for resumes
	#send_file('tmp/massive.png', :filename => 'massive.png')
	# File.read('tmp/massive.png')
	File.read(filename,length,start_at)
end

