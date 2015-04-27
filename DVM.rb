require 'set'

module DVM

	def self.assemble_byte_code_to_x64_binary(block,strings)
		writer = IntelAsmWriter.new
		writer.write_assembly block, strings
	end

	class BasicBlock
		attr_accessor :jump_to, :branch_to, :branch_on, :instructions, :label
		
		@@currentLabel = 0
		@@block_memo = Set.new

		def initialize
			@instructions = []
			@label = @@currentLabel
			@@currentLabel += 1
			
		end

		def print
			if @@block_memo.include? self
				return
			end

			if @instructions.count == 0
				return
			end

			@@block_memo.add self

			puts "BB" + @label.to_s + ":";
			puts @instructions;
			
			unless @branch_to.nil?
				puts "jump_not_equal " + @branch_on.to_s + ", 0  BB" + @jump_to.label.to_s
 				@branch_to.print
			end

			unless @jump_to.nil?
				puts "jump BB" + @jump_to.label.to_s
				@jump_to.print
			end
		end

		def add_instruction instruction
			@instructions << instruction
			self
		end
	end

	class Op
		attr_accessor :operation, :dest, :src1, :src2

		def initialize params
			@operation = params[:operation]
			@dest = params[:dest]
			@src1 = params[:src1]
			@src2 = params[:src2]
		end

		def to_s
			@operation.to_s + " " + @dest.to_s + " " + @src1.to_s + " " + @src2.to_s
		end

	end

	class IntelAsmWriter
		

		def write_assembly block,strings

			@output = ""
			write_header
			@output << "\n\nstart:\n\tjmp BB" << block.label.to_s
			@registerStack = ["r8", "r9", "r10", "r11", "r12", "r13", "r14"]
			@registerMap = {}
			@block_memo = Set.new
			write_block block;
			@output << "\tcall exit"

			@output << "\n\n\nsection .data\n\n"
			write_strings strings			

			return @output;
		end

		def write_header
			header = %{

global start

section .text

print_integer:              
	push 0x0a               
	mov r14, 1              
	stack_loop:
		mov rax, r15       
		xor rdx, rdx        
			mov rcx, 10         
		div rcx             
		add rdx, '0'        

		push rdx            
		mov r15, rax            
		inc r14               

	cmp r15, 0              
	jne stack_loop          

	print_loop:
		mov rsi, rsp        
		mov rdx, 1          
		mov rax, 0x2000004  
		mov rdi, 1          
		syscall             

		dec r14             
		pop r15             
		cmp r14, 0
		jne print_loop
		ret 

print_string:
	mov     rax, 0x2000004 
    mov     rdi, 1
    syscall
    ret

exit:
    mov rax, 0x2000001 ; exit
    mov rdi, 0
    syscall
			}

			@output << header
		end

		def write_strings strings
			strings.each_with_index {|string, index| 
				@output << "s" + index.to_s + ":\tdb\t" + string + ",10" + 
				"\n.len" + index.to_s + ":\tequ\t$ - s" + index.to_s + "\n"
			}
		end

		def write_block block
			if @block_memo.include? block
				return
			end

			@block_memo.add block

			@output << "\n\nBB" << block.label.to_s << ":\n"
			block.instructions.each {|n| @output << "\t" << dvm_op_to_x64_op(n) << "\n"}

			unless block.branch_to.nil?
				op = block.instructions.last;

				case op.operation
				when :greater_than
					@output << "\tjl BB"  << block.jump_to.label.to_s << "\n" 
 				when :lesser_than
					@output << "\tjg BB"  << block.jump_to.label.to_s << "\n" 
				when :equal
					@output << "\tjne BB"  << block.jump_to.label.to_s << "\n" 
				when :not_equal
					@output << "\tje BB"  << block.jump_to.label.to_s << "\n" 
				end

 				write_block block.branch_to;
			end

			unless block.jump_to.nil?
				@output << "\tjmp BB" << block.jump_to.label.to_s << "\n"
				write_block block.jump_to
			end
		end

		def dvm_op_to_x64_op op

			unless op.operation == :write_memory
				@registerMap[op.dest] = @registerStack.pop
				op.dest = @registerMap[op.dest];
			end
			
			case op.operation
			when :add, :subtract, :multiply, :divide, :greater_than, :modulo, :lesser_than, :equal, :not_equal
				if @registerMap[op.src1].nil?
					@registerMap[op.src1] = @registerStack.pop
				end
			
				op.src1 = @registerMap[op.src1];

				if @registerMap[op.src2].nil?
					@registerMap[op.src2] = @registerStack.pop
				end

				op.src2 = @registerMap[op.src2];

			when :print, :write_memory
				op.src1 = @registerMap[op.src1];
			end

			case op.operation
			when :add
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				return "add " + op.src1.to_s + ", " + op.src2.to_s + "\n\tmov " + op.dest.to_s + ", " + op.src1.to_s; 
			when :subtract
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				return "sub " + op.src1.to_s + ", " + op.src2.to_s + "\n\tmov " + op.dest.to_s + ", " + op.src1.to_s;
			when :multiply
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				return "imul " + op.src1.to_s + ", " + op.src2.to_s + "\n\tmov " + op.dest.to_s + ", " + op.src1.to_s;
			when :divide
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				return "idiv " + op.src1.to_s + ", " + op.src2.to_s + "\n\tmov " + op.dest.to_s + ", " + op.src1.to_s;
			when :modulo
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				return "mov rdx, 0\n\tmov rax, " + op.src1 + "\n\tmov rbx, " + op.src2 + "\n\tdiv " + op.src2.to_s + "\n\tmov " + op.dest.to_s + ", rdx"
			when :greater_than, :lesser_than, :equal, :not_equal
				@registerStack.unshift op.src1;
				@registerStack.unshift op.src2;
				@registerStack.unshift op.dest;
				@output << "cmp " + op.src1.to_s + ", " + op.src2.to_s
			when :load_constant
				return "mov " + op.dest.to_s + ", " + op.src1.to_s;
			when :load_memory
				return "mov " + op.dest.to_s + ", [rsp + " + op.src1.to_s + "]"
			when :write_memory
				@registerStack.unshift op.src1;
				return "mov " + "[rsp + " + op.dest.to_s + "], " + op.src1.to_s 
			when :print
				@registerStack.unshift op.src1;
				return "mov r15, " + op.src1.to_s + "\n\tcall print_integer"
			when :print_string
				return "mov rsi, s" + op.src1.to_s + "\n\tmov rdx, s" + op.src1.to_s + ".len" + op.src1.to_s + "\n\tcall print_string"
			end

			return ""
		end
	end

	

end