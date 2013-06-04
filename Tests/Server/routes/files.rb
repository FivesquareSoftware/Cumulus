include FileUtils
require 'digest'
require 'time'


before '/test/*/massive*' do
	@massive_filepath = 'resources/hs-2006-01-c-full_tif.png'
	@massive_filesize = File.size(@massive_filepath)
	@massive_etag = Digest.hexencode(@massive_filepath)
end

helpers do
	def download_massive(range = nil, etag = @massive_etag, date = Time.now.httpdate)
		filepath = @massive_filepath#'resources/hs-2006-01-c-full_tif.png'
		file_size = @massive_filesize

		Log.debug("range: #{range}")
		Log.debug("file_size: #{file_size}")

		length = file_size
		if range =~ /bytes=(\d+)-(\d+)?/
			start_at = $~.captures[0].to_i
			end_at = $~.captures[1].to_i
			if end_at == 0
				end_at = file_size
			end
			length = end_at-start_at+1
			Log.debug("start_at: #{start_at}")
			Log.debug("end_at: #{end_at}")
			headers('Content-Range' => "bytes #{start_at}-#{end_at}/#{file_size}" )
			if length < file_size
				status(206)
			end
		else
			headers('Content-Length' => length)
		end
		content_type('image/png')
		headers('Content-Disposition' => "attachment; filename=\"#{File.basename(filepath)}\"")
		if etag
			headers('ETag' => etag)
		elsif date
			headers('Last-Modified' => date)
		end
			

		File.read(filepath,length,start_at)
	end
end


## Hero

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
	headers('Content-Disposition' => 'attachment; filename="hero.png"')
	File.read('resources/t_hero.png')
end

## Massive

get '/test/stream/massive' do
	filepath = @massive_filepath#'resources/hs-2006-01-c-full_tif.png'
	content_type('image/png')
	send_file(filepath, :filename => File.basename(filepath))
end

head '/test/download/massive' do
	headers('Content-Length' => "#{@massive_filesize}")
end

get '/test/download/massive' do
	# send_file does not send content-length header if the file is over the buffer size which is bad bad for resumes
	#send_file('tmp/massive.png', :filename => 'massive.png')
	download_massive(request.env['HTTP_RANGE'])
end

get '/test/download/massive/etag/modified' do
	range = request.env['HTTP_RANGE']
	if range
		# fail the If-Range by etag
		# send the entire file
		# 200
		if_range = request.env['HTTP_IF_RANGE']
		# Log.debug("if_range: #{if_range}")
		# Log.debug("massive_etag: #{@massive_etag}")
		if if_range == @massive_etag
			download_massive
		else
			bad_request('Sent the wrong ETag')
		end
	else
		download_massive(nil,@massive_etag,nil)
	end
end

get '/test/download/massive/etag/notmodified' do
	range = request.env['HTTP_RANGE']
	if range
		# succeed the If-Range by etag
		# send the range
		# 206 - partial content	
		if_range = request.env['HTTP_IF_RANGE']
		# Log.debug("if_range: #{if_range}")
		# Log.debug("massive_etag: #{@massive_etag}")
		if if_range == @massive_etag
			download_massive(request.env['HTTP_RANGE'])
		else
			bad_request('Sent the wrong ETag')
		end
	else
		download_massive(nil,@massive_etag,nil)
	end
end

get '/test/download/massive/date/modified' do
	range = request.env['HTTP_RANGE']
	if range
		# fail the If-Range by last modified
		# send the entire file
		# 200
		if_range = Time.httpdate(request.env['HTTP_IF_RANGE'])
		Log.debug("if_range: #{if_range}")
		if if_range == nil
			bad_request('No date in If-Range')
		else
			download_massive
		end
	else
		download_massive(nil,nil)		
	end	
end

get '/test/download/massive/date/notmodified' do
	range = request.env['HTTP_RANGE']
	if range
		# succeed the If-Range by last modified
		# send the range
		# 206
		if_range = Time.httpdate(request.env['HTTP_IF_RANGE'])
		Log.debug("if_range: #{if_range}")
		if if_range == nil
			bad_request('No date in If-Range')
		else
			download_massive(request.env['HTTP_RANGE'])
		end
	else
		download_massive(nil,nil)
	end	
end

get '/test/download/massive/resume/fail' do
	range = request.env['HTTP_RANGE']
	Log.debug("range: #{range}")
	if range
			server_error('Massive Failure')
	else
		download_massive
	end	
end




