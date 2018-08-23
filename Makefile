DC=dmd

all: asm exec

asm:
	$(DC) crisc.d -of=criscasm -version=ASM

exec:
	$(DC) crisc.d -of=criscexec -version=CPU

install:
	cp criscasm /bin/criscasm
	cp criscexec /bin/criscexec