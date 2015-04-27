class DrewbyParser

option
  ignorecase

rule
  \s+
  \+				  { [:PLUS, text] }
  \-				  { [:MINUS, text] }
  \*				  { [:MULTIPLY, text] }
  \/				  { [:DIVIDE, text] }
  \%          { [:MODULO, text] }
  \>          { [:GREATERTHAN, text] }
  \<          { [:LESSERTHAN, text] }
  \==         { [:EQUAL, text] }
  \!=         { [:NOTEQUAL, text] }
  \=				  { [:ASSIGN, text] }
  \(				  { [:LPAREN, text] }
  \)				  { [:RPAREN, text] }
  \;          { [:SEMICOLON, text] }
  \{          { [:LBRACKET, text] }
  \}          { [:RBRACKET, text] }
  print       { [:PRINT, text] }
  while       { [:WHILE, text] }
  if          { [:IF, text] }
  else        { [:ELSE, text] }
  \d+       	{ [:NUMBER, text.to_i] }
  \"[^"]*\"   { [:STRING, text] }
  [a-zA-Z]*	 	{ [:VARIABLE, text] }
  . 				  {  [text, text] }


end
