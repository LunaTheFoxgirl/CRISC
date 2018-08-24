DC=dmd
LD_LIBRARY_PATH=$(F_BIN)
F_TMP=tmp/
F_BIN=bin/
SOURCE=src/

all: libcrisc exec asm cleanbuild
all32: libcrisc32 exec32 asm32 cleanbuild

configure:
	# Configure
	mkdir bin
	mkdir $(F_TMP)

libcrisc:
	# Build CRISC x86_64...
	$(DC) -m64 -c -fPIC $(SOURCE)crisc.d -of=$(F_TMP)crisc.o
	$(DC) -m64 $(F_TMP)crisc.o -shared -of=$(F_BIN)libcrisc.so -defaultlib=libphobos2.so -L-rpath=$(PWD)

libcrisc32:
	# Build CRISC x86...
	$(DC) -m32 -c -fPIC $(SOURCE)crisc.d -of=$(F_TMP)crisc.o -I=$(F_TMP)
	$(DC) -m32 $(F_TMP)crisc.o -shared -of=$(F_BIN)libcrisc32.so -defaultlib=libphobos2.so -L-rpath=$(PWD)

exec:
	$(DC) -I=$(SOURCE) -c $(SOURCE)criscfe.d $(SOURCE)ncurses.di -g -of=$(F_TMP)criscexec.o -version=CPU
	$(DC) $(F_TMP)criscexec.o -of=$(F_BIN)criscexec -L-lncurses -L-L\ $(F_BIN) -L-lcrisc -defaultlib=libphobos2.so

exec32:
	$(DC) -I=$(SOURCE) -m32 -c $(SOURCE)criscfe.d $(SOURCE)ncurses.di -g -of=$(F_TMP)criscexec.o -version=CPU
	$(DC) -m32 $(F_TMP)criscexec.o -of=$(F_BIN)criscexec32 -L-lncurses -L-L\ $(F_BIN) -L-lcrisc32 -defaultlib=libphobos2.so

asm:
	$(DC) -I=$(SOURCE) -c $(SOURCE)criscfe.d -g -of=$(F_TMP)criscasm.o -version=ASM
	$(DC) $(F_TMP)criscasm.o -of=$(F_BIN)criscasm -L-L\ $(F_BIN) -L-lcrisc -defaultlib=libphobos2.so

asm32:
	$(DC) -I=$(SOURCE) -m32 -c $(SOURCE)criscfe.d -g -of=$(F_TMP)criscasm.o -version=ASM
	$(DC) -m32 $(F_TMP)criscasm.o -of=$(F_BIN)criscasm32 -L-L\ $(F_BIN) -L-lcrisc32 -defaultlib=libphobos2.so

install:
	cp $(F_BIN)criscasm /bin/criscasm
	cp $(F_BIN)criscexec /bin/criscexec
	cp $(F_BIN)libcrisc.so /lib64/libcrisc.so

install32:
	cp $(F_BIN)criscasm /bin/criscasm32
	cp $(F_BIN)criscexec /bin/criscexec32
	cp $(F_BIN)libcrisc.so /lib/libcrisc.so

cleanbuild:
	rm -r $(F_TMP)

clean:
	rm -r $(F_BIN)

