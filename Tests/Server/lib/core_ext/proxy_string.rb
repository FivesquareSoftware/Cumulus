# Sinatra wants to turn strings into arrays of strings, which is not good 
# for json output where we want strings to be acceptable
class ProxyString < String
	undef_method :to_str	
end