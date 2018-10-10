/*
	Copyright (C) 2018  Clipsey

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
module criscfe;
import crisc;
import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.file;
import std.algorithm;

enum licenseTextHeader = "CRISC ASM v. 1.0, Copyright (C) 2018 Clipsey
CRISC ASM is licensed under the GPLv2 license.
Run with -co for details.
";

enum licenseTextHeaderExec = "CRISC EXEC v. 1.0, Copyright (C) 2018 Clipsey
CRISC EXEC is licensed under the GPLv2 license.
Run with -co for details.
";

enum licenseText = "Copyright (C) 2018  Clipsey

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
";

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
			import std.stdio;
			write(c);
		}
	}
}

void main(string[] args)
{
	version(CPU) {
		if (args.length <= 1) {
			writeln(licenseTextHeaderExec);
			writeln("Usage
\tcriscexec <file>");
			return;
		}
		if (args[1] == "--copyright" || args[1] == "-co") {
			writeln(licenseText);
			return;
		}
		auto processor = new CPU(cast(ubyte[])read(args[1]), 32, 512);
		processor.PushSyscalls([
			new SysCallPrtC(processor)]
		);
		while (processor.running) {
			processor.runCycle();   
		}
	}

	version (ASM) {
		bool verbose = false;
		bool link = false;
		bool conv = false;

		string linkTmp = "";
		string firstFile = "";
		string outFile = "";

		writeln(licenseTextHeader);

		foreach (file; args[1..$]) {
			if (file.startsWith("-")) {
				if (file == "--verbose" || file == "-v") {
					verbose = true;
				}
				if (file == "--link" || file == "-l") {
					link = true;
				}
				if (file == "--copyright" || file == "-co") {
					writeln(licenseText);
					return;
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
					auto compiler = new Compiler(true, [new SysCallPrtC()]);
					output.rawWrite(compiler.compile(readText(file)));
					if (verbose) compiler.printLabels();
					output.close();
				}
			}
		}

		if (link) {
			outFile  = firstFile[0..$-3]~"bin";
			File output = File(outFile, "w");
			auto compiler = new Compiler(true, [new SysCallPrtC()]);
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
\t--verbose/-v       | Verbose mode
\t--link/-l          | Link asm files together (output will be named after the first file)
\t--conv/-c          | Assemble and view human-readable conversion of assembly
\t--copyright/-co    | View license.");
		}
	}
}
