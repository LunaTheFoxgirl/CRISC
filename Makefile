DC=dmd

all: asm exec cleanbuild

asm:
	$(DC) crisc.d -of=criscasm -version=ASM

exec:
	$(DC) crisc.d -of=criscexec -version=CPU

install:
	cp criscasm /bin/criscasm
	cp criscexec /bin/criscexec

cleanbuild:
	rm *.o

clean:
	rm criscasm criscexec
