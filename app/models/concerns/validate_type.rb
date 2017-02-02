class ValidateType
	def isNumber(number)
		begin 
			if number.class == Fixnum
				number
			else
				if number.match(/[a-z]/)
					raise TypeError
				else
					number.to_i
				end
			end
		rescue Exception => e
			{error: e.message}
		end
	end
end