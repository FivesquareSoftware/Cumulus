# Sinatra wants to treat all arrays as arrays of strings which is not good 
# for json output where we want arrays of objects to be acceptable
class ProxyArray < Array
	undef_method :to_ary	
end