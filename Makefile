DC=dmd
LD_LIBRARY_PATH=.

all: libcrisc exec asm cleanbuild
all32: libcrisc32 exec32 asm32 cleanbuild

libcrisc:
	# 64 bit
	$(DC) -m64 -c -fPIC crisc.d
	$(DC) -m64 crisc.o -shared -of=libcrisc.so -defaultlib=libphobos2.so -L-rpath=$(PWD)

libcrisc32:
	# 32 bit
	$(DC) -m32 -c -fPIC crisc.d
	$(DC) -m32 crisc.o -shared -of=libcrisc.so -defaultlib=libphobos2.so -L-rpath=$(PWD)

exec:
	$(DC) -c criscfe.d ncurses.di -g -of=criscexec.o -version=CPU
	$(DC) criscexec.o  -L-lncurses -Llibcrisc.so -defaultlib=libphobos2.so -L-rpath=.

exec32:
	$(DC) -m32 -c criscfe.d ncurses.di -g -of=criscexec.o -version=CPU
	$(DC) -m32 criscexec.o  -L-lncurses -Llibcrisc.so -defaultlib=libphobos2.so -L-rpath=.

asm:
	$(DC) -c criscfe.d -g -of=criscasm.o -version=ASM
	$(DC) criscasm.o -Llibcrisc.so -defaultlib=libphobos2.so -L-rpath=.

asm32:
	$(DC) -m32 -c criscfe.d -g -of=criscasm.o -version=ASM
	$(DC) -m32 criscasm.o -Llibcrisc32.so -defaultlib=libphobos2.so -L-rpath=.

install:
	cp criscasm /bin/criscasm
	cp criscexec /bin/criscexec
	cp libcrisc.so /lib64/libcrisc.so

install32:
	cp criscasm /bin/criscasm32
	cp criscexec /bin/criscexec32
	cp libcrisc.so /lib/libcrisc.so

cleanbuild:
	rm *.o

clean:
	rm *.so
	rm criscasm criscexec
