module AST

	class ASTNode

		attr_accessor :operation, :left, :right, :value, :register, :sub_statements
		
		@@currentRegister = 0

		def initialize params
			@register = @@currentRegister;
			@@currentRegister +=1
			@sub_statements = params[:sub_statements]
		end

		def to_s
			case @operation
			when :print
				return 'PrintStatement'
			when :write_memory
				return 'WriteMemory'
			when :if
				ifStatements = @sub_statements.reduce {|memo, obj| memo.to_s + ',' + obj.to_s }
				elseStatements =  @right.sub_statements.reduce {|memo, obj| memo.to_s + ',' + obj.to_s }
				return "If:" + ifStatements + "\nElse:" + elseStatements;
			end
		end

		def emit_byte_code
			@currentBlock = DVM::BasicBlock.new();

			#Process Left and Right Branches.
			unless @left.nil?
				@currentBlock.instructions += @left.emit_byte_code.instructions
			end

			unless @right.nil?
				@currentBlock.instructions += @right.emit_byte_code.instructions
			end
			
			unless self.byte_code_op.nil?
				@currentBlock.instructions << self.byte_code_op
			end

			return @currentBlock
		end

		def emit_byte_code_for_substatements
		root = DVM::BasicBlock.new();
		current_block = DVM::BasicBlock.new();
		@sub_statements.each_with_index { |node, index| 
				current_block.jump_to = node.emit_byte_code(); 
				until current_block.jump_to.nil?
					current_block = current_block.jump_to;
				end

				if (index == 0)
					root = current_block;
				end
			}
		current_block.jump_to = DVM::BasicBlock.new();
		return root;
	end

	end

	class MultiplyExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :multiply, dest:@register, src1:@left.register, src2:@right.register})	
		end
	end

	class AddExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :add, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class SubtractExpression < ASTNode
		
		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :subtract, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class DivideExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :divide, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class ModuloExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :modulo, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class GreaterThanExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :greater_than, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class LesserThanExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :lesser_than, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class EqualExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :equal, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class NotEqualExpression < ASTNode

		def initialize params
			super
			@left = params[:left_expression]
			@right = params[:right_expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :not_equal, dest:@register, src1:@left.register, src2:@right.register})
		end
	end

	class LoadConstantExpression < ASTNode

		def initialize params
			super
			@value = params[:value]
		end

		def byte_code_op
			DVM::Op.new({operation: :load_constant, dest:register, src1:@value})
		end
	end

	class LoadVariableExpression < ASTNode

		def initialize params
			super
			variable_location = SymbolTable.getMemoryLocation(params[:variable_name])
			@value = variable_location.to_s
		end

		def byte_code_op
			DVM::Op.new({operation: :load_memory, dest:register, src1:@value})
		end
	end

	class AssignVariableStatement < ASTNode
		def initialize params
			super
			@left = params[:expression]
			variable_location = SymbolTable.getMemoryLocation(params[:variable_name])
			@value = variable_location.to_s
		end

		def byte_code_op
			DVM::Op.new({operation: :write_memory, dest:@value, src1:@left.register})
		end
		
	end

	class PrintStatement < ASTNode
		def initialize params
			super
			@left = params[:expression]
		end

		def byte_code_op
			DVM::Op.new({operation: :print, dest:nil, src1:@left.register})
		end
	end

	class PrintStringStatement < ASTNode
		def initialize params
			super
			@value = SymbolTable.add_string params[:text]
		end

		def byte_code_op
			DVM::Op.new({operation: :print_string, dest:nil, src1:@value})
		end
	end

	class IfStatement < ASTNode
		def initialize params
			super
			@left = params[:expression]
			@sub_statements = params[:statements]
		end

		def emit_byte_code
			block = super
			block.branch_on = @left.register
			block.branch_to = self.emit_byte_code_for_substatements
			block.instructions = @left.emit_byte_code.instructions
			block
		end

		def byte_code_op
			nil
		end
	end

	class WhileStatement < ASTNode
		def initialize params
			super
			@left = params[:expression]
			@sub_statements = params[:statements]
		end

		def emit_byte_code
			block = super
			block.branch_on = @left.register
			block.branch_to = self.emit_byte_code_for_substatements
			
			end_block = block.branch_to
			until end_block.jump_to.nil?
				end_block = end_block.jump_to
			end

			end_block.jump_to = block
			
			block.instructions = @left.emit_byte_code.instructions;
			block
		end

		def byte_code_op
			nil
		end
	end

end

