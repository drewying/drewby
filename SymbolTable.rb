class SymbolTable
	@@currentMemoryLocation = 0
	@@table = {}
	@@string_table = []

	def self.getMemoryLocation(symbol)
		unless @@table.has_key?(symbol)
			@@table[symbol] = @@currentMemoryLocation
			@@currentMemoryLocation += 8
		end
		@@table[symbol]
	end

	def self.add_string(string)
		unless @@string_table.include? string
			@@string_table << string
		end
		@@string_table.index string
	end

	def self.get_strings
		@@string_table
	end

end