all: mini_js in.txt
	./mini_js < in.txt > out.txt

d: mini_js_debug in.txt
	./mini_js_debug < in.txt > out.txt

lex.yy.c: mini_js.l
	lex mini_js.l

y.tab.c: mini_js.y
	yacc mini_js.y

mini_js: lex.yy.c y.tab.c
	g++ -o mini_js y.tab.c -ll

mini_js_debug: lex.yy.c y.tab.c
	g++ -o mini_js_debug y.tab.c -ll -DDEBUG=1
