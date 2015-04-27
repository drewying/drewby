require './Scanner.rb'
require './Parser.rb'
require './SymbolTable.rb'
require './AbstractSyntaxTree.rb'
require './DVM.rb'


begin
  parser = DrewbyParser.new  
  puts "Step 1 and 2: Tokenizing and Parsing file " + ARGV[0] + "..."
  main_tree = parser.scan_file(ARGV[0])
  
  puts "Step 3 Writing Byte Code..."
  control_flow_graph = main_tree.emit_byte_code_for_substatements
  
  puts "Step 4 Converting Byte Code into x64 machine code."
  asm = DVM::assemble_byte_code_to_x64_binary control_flow_graph, SymbolTable.get_strings
  File.write('out.asm', asm)

  puts "Step 4 Linking x64 machine code into a binary."
  %x(nasm -f macho64 out.asm)
  %x(ld -o out out.o -macosx_version_min 10.7)
  
  puts "Output binary written to file 'out'"

rescue ParseError
  puts 'parse error'
end
