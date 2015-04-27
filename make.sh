echo Preprocessing..
rm ./out.asm
rm ./out
rex Drewby.rex -o Scanner.rb
racc Drewby.racc -o Parser.rb
echo Done