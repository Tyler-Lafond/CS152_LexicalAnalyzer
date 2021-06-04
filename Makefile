CFLAGS = -g -Wall -ansi -pedantic

mini_1: mini_l.lex mini_l.y
	bison -v -t -d --file-prefix=y mini_l.y
	flex mini_l.lex
	g++ ${CFLAGS} -std=c++11 lex.yy.c y.tab.c -lfl -o mini_l
	rm -f lex.yy.c *.output *.tab.c *.tab.h

test: mini_l
	cat ./tests/min/primes.min | ./mini_l > ./tests/mil/primes.mil
	cat ./tests/min/mytest.min | ./mini_l > ./tests/mil/mytest.mil
	cat ./tests/min/fibonacci.min | ./mini_l > ./tests/mil/fibonacci.mil
	cat ./tests/min/errors.min | ./mini_l > ./tests/mil/errors.mil
	cat ./tests/min/custom.min | ./mini_l > ./tests/mil/custom.mil
