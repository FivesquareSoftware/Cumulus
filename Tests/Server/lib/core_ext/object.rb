class Object
	def json_proxy
		case self
		when Exception
			{ :name => self.class.name, :message => self.message, :backtrace => self.backtrace }
		when String
			#ProxyString.new(self)
			self
		when Integer
			self
		when Hash
			self
		when Array
			#ProxyArray.new(self.collect{|a| a.respond_to?(:attributes) ?	 a.attributes : a })
			self.collect{|a| a.json_proxy }
		else
			if self.respond_to?(:to_json)
				self
			else
				raise "Cannot turn a #{self.class.name} into json"
			end
		end
	end
end
