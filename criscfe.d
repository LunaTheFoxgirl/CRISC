module criscfe;
import crisc;
import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.file;
import std.algorithm;

class SysCallPrtC : SysCall {

	this() {
		super("prtc");
	}

	this(CPU valueptr) {
		super("prtc", valueptr);
	}

	public override void execute() {
		version(CPU) {
			char c = cast(char)valueptr.pop();
			import ncurses;
			switch(c) {
				case(127):
					int x;
					int y;
					int w;
					int h;
					getyx(stdscr, &x, &y);
					getmaxyx(stdscr, &w, &h);
					
					x--;
					if ( x < 0 ) {
						x = w-1;
						y--;
					}
					if ( y < 0 ) {
						y = 0;
						x = 0;
					}
					mvdelch(y, x);
				break;
				default:		printw([c, '\0'].ptr);		break;
			}
			refresh();
		}
	}
}

class SysCallReadC : SysCall {

	this() {
		super("rdc");
	}

	this(CPU valueptr) {
		super("rdc", valueptr);
		version(CPU) {
			import ncurses;
			initscr();
			noecho();
			//keypad(stdscr, true);
			//raw();
		}
	}

	public override void execute() {
		version(CPU) {
			import ncurses;
			char code = cast(char)getch();
			valueptr.push(cast(size_t)code);
		}
	}
}

void main(string[] args)
{
	version(CPU) {
		auto processor = new CPU(cast(ubyte[])read(args[1]), 32, 512);
		processor.PushSyscalls([
			new SysCallPrtC(processor), 
			new SysCallReadC(processor)]
		);
		while (processor.running) {
			processor.runCycle();   
		}
		if (args.length <= 1) {
			writeln("Usage
\tcriscexec <file>");
		}
	}

	version (ASM) {
		bool verbose = false;
		bool link = false;
		bool conv = false;

		string linkTmp = "";
		string firstFile = "";
		string outFile = "";

		foreach (file; args[1..$]) {
			if (file.startsWith("-")) {
				if (file == "--verbose" || file == "-v") {
					verbose = true;
				}
				if (file == "--link" || file == "-l") {
					link = true;
				}
				if (file == "--conv" || file == "-c") {
					conv = true;
				}
			} else {
				if (firstFile == "") firstFile = file;
				if (link) {
					linkTmp ~= "\n"~readText(file);
				} else {
					outFile = file[0..$-3]~"bin";
					File output = File(outFile, "w");
					auto compiler = new Compiler(true, [new SysCallPrtC(), new SysCallReadC()]);
					output.rawWrite(compiler.compile(readText(file)));
					if (verbose) compiler.printLabels();
					output.close();
				}
			}
		}

		if (link) {
			outFile  = firstFile[0..$-3]~"bin";
			File output = File(outFile, "w");
			auto compiler = new Compiler(true, [new SysCallPrtC(), new SysCallReadC()]);
			output.rawWrite(compiler.compile(linkTmp));
			if (verbose) compiler.printLabels();
			output.close();
		}
		
		if (conv) 
			writeln(binToASMDESC(cast(ubyte[])read(outFile)));

		if (args.length <= 1) {
			writeln("Usage
criscasm (flags) <files>
Flags
\t--verbose/-v | verbose mode
\t--link/-l    | link asm files together (output will be named after the first file)
\t--conv/-c    | assemble and view human-readable conversion of assembly");
		}
	}
}
