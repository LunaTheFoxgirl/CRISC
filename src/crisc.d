module crisc;
import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.file;
import std.algorithm;

public enum DBGOpCode : uint {
	// PRINT a register
	PRT_REG = 0,
	
	// PRINT the program counter
	PRT_CTR = 1,
	
	// PRINT the program cycles
	PRT_CYC = 2,
	
	// PRINT the writable memory
	PRT_WMEM = 3,

	// PRINT the full memory.
	PRT_FMEM = 4,

	// PRINT memory range
	PRT_MEMR = 5,

	// PRINT the callstack.
	PRT_CSTK = 6,

	// PRINT the datastack.
	PRT_DSTK = 7,

	// SET verbose logging output
	SET_VEB = 8,

	// SET verbose logging for data stack operations.
	SET_VSTK = 9,
}

public enum OpCode : ubyte {
    // Kill program
    HALT = 0,
    
    // Move REG A to REG B
	MOV = 1,
    
    // Move CONST A to REG B
	MOVC = 2,
    
    // Move REG (Referenced by CONST) A to REG B
	MOVR = 3,
    
    ADD = 4,
    
    // Add CONST A to REG B
    ADDC = 5,
    
    // Add REG (Referenced by CONST) A to REG B
    ADDR = 6,
    
    // Subtract REG A to REG B
    SUB = 7,
    
    // Subtract CONST A to REG B
    SUBC = 8,
    
    // Subtract REG (Referenced by CONST) A to REG B
    SUBR = 9,
        
    // Multiply REG A to REG B
    MUL = 10,
    
    // Multiply CONST A to REG B
    MULC = 11,
    
    // Multiply REG (Referenced by CONST) A to REG B
    MULR = 12,
    
    // Divide REG A to REG B
    DIV = 13,
    
    // Divide CONST A to REG B
    DIVC = 14,
    
    // Divide REG (Referenced by CONST) A to REG B
    DIVR = 15,

    // JUMP TO ADDRESS A
	JMP = 16,

    // JUMP TO CONST A
	JMPC = 17,
    
    // JUMP TO ADDRESS A IF STATUS register is NOT EQUAL to CONST
	JMPNEQ = 18,
    
    // JUMP TO ADDRESS A IF STATUS register is EQUAL to CONST
	JMPEQ = 19,
    
    // JUMP TO ADDRESS A IF STATUS register is EQUAL or LARGER than CONST B
	JMPLEQ = 20,
    
    // JUMP TO ADDRESS A IF STATUS register is EQUAL or SMALLER than CONST B
    JMPSEQ = 21,
    
    // JUMP TO CONST A IF STATUS register is NOT EQUAL to CONST
	JMPNEQC = 22,
    
    // JUMP TO CONST A IF STATUS register is EQUAL to CONST
	JMPEQC = 23,
    
    // JUMP TO CONST A IF STATUS register is EQUAL or LARGER than CONST B
	JMPLEQC = 24,
    
    // JUMP TO CONST A IF STATUS register is EQUAL or SMALLER than CONST B
    JMPSEQC = 25,
    
	// LOAD VALUE to REG A from (Referenced by CONST) MEMORY ADDRESS B
	LDR = 26,

	// LOAD VALUE TO REG A from (Referenced by CONST) MEMORY ADDRESS B
	LDRC = 27,

	// STORE VALUE from REG A to (Referenced by CONST) MEMORY ADDRESS B
	STR = 28,

	// STORE VALUE OF REG A to (Referenced by CONST) MEMORY ADDRESS B
	STRC = 29,
	
	// CALL jump to address referenced by CONST A and set stack return pointer
	CALL = 30,

	// CALL system level function.
	SCALL = 31,
	
    // PUSH value to stack
	PUSH = 32,

    // PUSH value to stack
	PUSHC = 33,
	
	// POP value from stack
	POP = 34,
	
	// RETURN returns to the last stack pointer with values
    RET = 35,
	
	// DBG debugging functionality
	DBG = 36
}

struct Instruction {
    OpCode opCode;
    size_t[2] data;
}

struct CPUStack {
	private {
		size_t size;
		ubyte* stackptr;
		size_t stackoffset;
	}

	public {
		void clearStack() {
			stackoffset = 0;
			while (stackoffset < size) {
				stackpointer_t[stackoffset] = 0;
				stackoffset++;
			}
			stackoffset = 0;
		}

		ubyte* stackpointer() {
			return stackptr+stackoffset;
		}

		size_t* stackpointer_t() {
			return (cast(size_t*)stackptr)+stackoffset;
		}

		void push(size_t item) {
			checkBounds(1);
			*((cast(size_t*)stackpointer_t)) = item;
			stackoffset += 1;
		}

		size_t pop() {
			checkBounds(-1);
			stackoffset -= 1;
			size_t item = *((cast(size_t*)stackpointer_t));
			return item;
		}

		void checkBounds(long offset) {
			if (offset < 0) {
				if (stackoffset == 0 || cast(long)(stackoffset)-offset < 0) throw new Exception("Stack underflow");
			} else {
				if (stackoffset+offset > size)
					throw new Exception("Stack overflow!\nStack:\n"~stackStr);
			}
		}

		string stackStr() {
			return to!string((stackpointer_t-stackoffset)[0..size]) ~ "; OFFSET=" ~ to!string(stackoffset);
		}
	}
}

class SysCall {
	public string name;

	this(string name) {
		this.name = name;
	}

	this(string name, CPU owner) {
		this.name = name;
		this.valueptr = &owner.datastack;
	}

	this(string name, CPUStack* stack) {
		this.name = name;
		this.valueptr = stack;
	}

	protected CPUStack* valueptr;
	public abstract void execute();
}

class SysCallGetSafeMem : SysCall {
	CPU cpu;

	this() {
		super("gsfm");
	}

	this(CPU cpu) {
		super("gsfm", cpu);
		this.cpu = cpu;
	}

	public override void execute() {
		valueptr.push(cast(size_t)cpu.safeMemOffset);
	}
}

class CPU {
    // Program counter/program pointer.
    Instruction* progptr;

    // Pointer to start of program
    Instruction* progstart;
    
	size_t progctr() {
		return progptr-progstart;
	}

	// List of system calls (NOTE NEEDS TO BE IN SAME ORDER AS ASSEMBLED)
	SysCall[] syscalls;

	// Registers
    ulong[256] REGISTERS;

	// Pointer to status register (0xFF)
	ulong* STATUS_REG;

	// Call stack
	CPUStack callstack;
	
	// Data stack
	CPUStack datastack;

	// The memory in which the program resides.
    ubyte[] memory;

	// safe memory space offset
	size_t safeMemOffset;

	// Amount of operations/instructions program has run
    ulong cOps = 0;

	// Sizes for stacks
	ulong callstackSize;
	ulong stackStoreSize;
	
	// Verbose and Stack Verbose
	bool VEB = false;
	bool SVEB = false;
    
    bool running() {
        return (progptr !is null);
    }
   

    this(ubyte[] program, size_t stackSize, size_t memorySize) {
		// Set up status register pointer.
		STATUS_REG = &REGISTERS[255];
		
		// Prepare memory.
		memory = program;
		memory.length += stackSize;
		memory.length += memorySize;

		// Set stack pointer.
		CPUStack cstack = { size:stackSize, stackptr:memory.ptr+program.length, stackoffset:0 };
		callstack = cstack;

		// Set stack pointer for data.
		CPUStack dstack = { size:stackSize, stackptr:(memory.ptr+program.length)+(size_t.sizeof*stackSize), stackoffset:0 };
		datastack = dstack;

		// Set program counter and program start pointer
		progstart = cast(Instruction*)memory.ptr;
		progptr = progstart;
		
		// Clear stacks
		callstack.clearStack();
		datastack.clearStack();

		safeMemOffset = (program.length)+((size_t.sizeof*stackSize)*2);

		// Add ptrc and rdc syscalls.
		this.syscalls = cast(SysCall[])[new SysCallGetSafeMem(this)];
    }
    
	public void PushSyscalls(SysCall[] syscalls) {
		this.syscalls ~= syscalls;
	}

    void runCycle() {
        if (progptr is null) return;
        REGISTERS[254] = cast(size_t)callstack.stackpointer;
		debugInstr(*progptr);
        switch (progptr.opCode) {

            case(OpCode.MOV):	REGISTERS[progptr.data[1]] = REGISTERS[progptr.data[0]]; 	break;
            case(OpCode.MOVC):	REGISTERS[progptr.data[1]] = progptr.data[0]; 				break;
			case(OpCode.MOVR):	REGISTERS[REGISTERS[progptr.data[1]]] = progptr.data[0]; 	break;

            case(OpCode.ADD):	REGISTERS[progptr.data[1]] += REGISTERS[progptr.data[0]]; 	break;
            case(OpCode.ADDC):	REGISTERS[progptr.data[1]] += progptr.data[0]; 				break;
            case(OpCode.ADDR):	REGISTERS[REGISTERS[progptr.data[1]]] += progptr.data[0]; 	break;

            case(OpCode.SUB):	REGISTERS[progptr.data[1]] -= REGISTERS[progptr.data[0]]; 	break;
            case(OpCode.SUBC):	REGISTERS[progptr.data[1]] -= progptr.data[0]; 				break;
            case(OpCode.SUBR):	REGISTERS[REGISTERS[progptr.data[1]]] -= progptr.data[0]; 	break;

            case(OpCode.MUL): 	REGISTERS[progptr.data[1]] *= REGISTERS[progptr.data[0]]; 	break;
            case(OpCode.MULC): 	REGISTERS[progptr.data[1]] *= progptr.data[0]; 				break;
            case(OpCode.MULR): 	REGISTERS[REGISTERS[progptr.data[1]]] *= progptr.data[0]; 	break;

            case(OpCode.DIV): 	REGISTERS[progptr.data[1]] /= REGISTERS[progptr.data[0]]; 	break;
            case(OpCode.DIVC): 	REGISTERS[progptr.data[1]] /= progptr.data[0]; 				break;
            case(OpCode.DIVR): 	REGISTERS[REGISTERS[progptr.data[1]]] /= progptr.data[0]; 	break;

            case(OpCode.JMP):	progptr = progstart+(REGISTERS[progptr.data[0]])-1;			break;

            case(OpCode.JMPEQ):
				if (*STATUS_REG == REGISTERS[progptr.data[1]]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPNEQ):
 	            if (*STATUS_REG != REGISTERS[progptr.data[1]]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPLEQ):
 	            if (*STATUS_REG >= REGISTERS[progptr.data[1]]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPSEQ):
 	            if (*STATUS_REG <= REGISTERS[progptr.data[1]]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPC):	progptr = progstart+(progptr.data[0])-1;					break;

            case(OpCode.JMPEQC):
 	            if (*STATUS_REG == progptr.data[1]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPNEQC):
 	            if (*STATUS_REG != progptr.data[1]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPLEQC):
 	            if (*STATUS_REG >= progptr.data[1]) progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.JMPSEQC):
 	            if (*STATUS_REG <= progptr.data[1]) progptr = progstart+(progptr.data[0])-1;
            	break;

			case(OpCode.DBG):
            	if (progptr.data[0] == DBGOpCode.PRT_REG) writeln("REG_", progptr.data[1], "=", REGISTERS[progptr.data[1]]);
            	if (progptr.data[0] == DBGOpCode.PRT_CTR) writeln("PROG_CTR=", progptr);
            	if (progptr.data[0] == DBGOpCode.PRT_CYC) writeln("CYCLES=", cOps);
            	if (progptr.data[0] == DBGOpCode.PRT_WMEM) writeln("MEMORY MAP=", to!string(memory));
            	if (progptr.data[0] == DBGOpCode.PRT_DSTK) writeln("DATASTACK=", datastack.stackStr);
            	if (progptr.data[0] == DBGOpCode.PRT_CSTK) writeln("CALLSTACK=", callstack.stackStr);
				if (progptr.data[0] == DBGOpCode.PRT_MEMR) writeln(to!string(readMemRange(REGISTERS[253], progptr.data[1])));


				if (progptr.data[0] == DBGOpCode.SET_VEB) VEB = cast(bool)progptr.data[1];
				if (progptr.data[0] == DBGOpCode.SET_VSTK) SVEB = cast(bool)progptr.data[1];
            	break;

            case(OpCode.CALL):
				if (progptr.data[0] < 0) throw new Exception("CPU HALT; ACCESS OUT OF BOUNDS");
				callstack.push(progctr+1);
				if (SVEB) writeln("DATASTACK=", datastack.stackStr);
            	progptr = progstart+(progptr.data[0])-1;
            	break;

            case(OpCode.SCALL):	syscalls[progptr.data[0]].execute();	break;

            case(OpCode.RET):
				size_t tptr = callstack.pop();
            	progptr = progstart+tptr-1;
				if (SVEB) writeln("DATASTACK=", datastack.stackStr);
            	break;

            case(OpCode.PUSHC):
           		datastack.push(progptr.data[0]);
				if (SVEB) writeln("DATASTACK=", datastack.stackStr);
            	break;

            case(OpCode.PUSH):
           		datastack.push(REGISTERS[progptr.data[0]]);
				if (SVEB) writeln("DATASTACK=", datastack.stackStr);
            	break;

            case(OpCode.POP):
           		REGISTERS[progptr.data[0]] = datastack.pop();
				if (SVEB) writeln("DATASTACK=", datastack.stackStr);
				break;

            case(OpCode.LDR):	REGISTERS[progptr.data[1]] = readMem(REGISTERS[progptr.data[0]]);			break;
			case(OpCode.LDRC):	REGISTERS[progptr.data[1]] = readMem(progptr.data[0]);	break;

            case(OpCode.STR):	writeMem(REGISTERS[progptr.data[1]], REGISTERS[progptr.data[0]]);				break;
			case(OpCode.STRC):	writeMem(REGISTERS[progptr.data[1]], progptr.data[0]);							break;

            case(OpCode.HALT):
           		writeln("PROGRAM HALTED.");
         		progptr = null;
            	break;

            default:
				writeln("INVALID OPERATION @", progptr-progstart);
				break;
        }
		if (progptr is null) return;
        progptr++;
        cOps++;
    }

	private size_t readMem(size_t address) {
		size_t value = *cast(size_t*)(cast(ubyte*)memory+address);
		//writeln("Reading ", value, " fom ", address);
		return value;
	}

	private size_t[] readMemRange(size_t address, size_t length) {
		//writeln("Reading address ", address, " to ", address+length);
		return (cast(size_t*)((cast(ubyte*)memory+address)[0..length]))[0..length/size_t.sizeof];
	}

	private void writeMem(size_t address, size_t value) {
		//writeln("Writing ", value, " to ", address);
		*cast(size_t*)(cast(ubyte*)memory+address) = value;
	}

	private void debugInstr(Instruction instr) {
		if (VEB) writeln(to!string((cast(OpCode)instr.opCode)), " ", instr.data[0], " ", instr.data[1]);
	}
}

struct Label {
	string name;
	size_t offset;
}

struct LabelRef {
	string name;
	size_t doffset;
	size_t offset;
}

class Compiler {
	private LabelRef[] labelRefs;
	private Instruction[] code;
	private Label[] labels;
	private bool doInfer;

	private SysCall[] syscalls;

	public this(bool infer, SysCall[] syscalls) {
		this.doInfer = infer;

		// Add ptrc and rdc syscalls.
		this.syscalls = cast(SysCall[])[new SysCallGetSafeMem()] ~ syscalls;
	}

	public ubyte[] compile(string asmCode) {
		// Process lines in program, removing/ignoring comments.
		string[] lines = asmCode.split('\n');
		string[] keywords;
		foreach(string line; lines) {
			string lo = "";
			bool isComment = false;
			foreach (char c; line) {
				if (c == ';') isComment = true;
				if (!isComment) lo ~= c;
			}
			foreach (string keyword; lo.split) {
				if (keyword != "") keywords ~= keyword;
			}
		}
		

		// Convert text/asm to instructions.
		bool parsingCompleted = false;
		int i = 0;
		uint instr_pos = 0;
		while (!parsingCompleted) {
			try {
				// Generate labels.
				if (i >= keywords.length) break;
				if (keywords[i].endsWith(":")) {
					Label l = { keywords[i][0..$-1], instr_pos };
					labels ~= l;
				} else {
					// Preprocessing
					OpCode opCode = getOp(keywords[i]);
					string kw = keywords[i];

					// Specifies whether the assembler should infer which instruction to use based on how the arguments are structured.
					if (doInfer) {
						if (opCode != OpCode.HALT && opCode != OpCode.RET && opCode != OpCode.DBG && opCode != OpCode.CALL && opCode != OpCode.SCALL) {
							int r = 1;
							if (kw.toUpper.startsWith("JMP")) {
								r = 2;
							}
							if (!keywords[i+r].startsWith("@")) {
								if (opCode == OpCode.POP) throw new Exception("Invalid operation, \""~kw~"\" [arg a] takes an register, not a constant!");
								// Handle references.
								kw ~= "C";
							}
							if (!kw.toUpper.startsWith("JMP")) {
								if (opCode != OpCode.POP && opCode != OpCode.JMP && opCode != OpCode.PUSH) {
									if (!keywords[i+2].startsWith("@")) throw new Exception("Invalid operation, \""~kw~"\" [arg b] takes an register, not a constant!");
								}
							}
						}
					}

					// Generate instructions.
					opCode = getOp(kw);

					string argAStr = "";
					if (i+1 < keywords.length) argAStr = keywords[i+1];
					uint argA = 0;

					string argBStr = "";
					if (i+2 < keywords.length) argBStr = keywords[i+2];
					uint argB = 0;
					if (opCode != OpCode.HALT && opCode != OpCode.RET) {
						if (opCode == OpCode.DBG) {
							argA = getDBGOp(argAStr);
						} else if (opCode == OpCode.SCALL) {
							argA = getSyscall(argAStr);
						} else {
							argA = getVal(labels, 0, argAStr);
						}

						// Iterate
						i++;
						
						if (opCode != OpCode.CALL && opCode != OpCode.SCALL && opCode != OpCode.PUSH && opCode != OpCode.PUSHC && opCode != OpCode.POP && opCode != OpCode.JMP && opCode != OpCode.JMPC) {
							argB = getVal(labels, 1, argBStr);

							// Iterate
							i++;
						}
						
					}
					Instruction instr = { opCode, [argA, argB] };
					code ~= instr;
					instr_pos++;
				}
				// Iterate
				i++;
				if (i >= keywords.length) parsingCompleted = true;
			} catch (Exception ex) {
				writeln("Error @ index ", i, ", token=", keywords[i], " message=", ex.message);
				return null;
			}
		}

		// Post processing (label conversion)
		foreach(Label l; labels) {
			size_t x = 0;
			while (true) {
				if (x >= labelRefs.length) break;
				LabelRef lref = labelRefs[x];
				Instruction* instr = &code[lref.offset];
				if (lref.name == l.name) {
					instr.data[lref.doffset] = cast(uint)l.offset;
					labelRefs = labelRefs.remove(x);
					continue;

					//throw new Exception("Invalid reference to label for OPCode "~to!string(cast(OpCode)(instr.opCode)));
				}
				x++;
			}
		}

		return cast(ubyte[])code;
	}

	uint getValLabels(Label[] labels, string label) {
		foreach(Label l; labels) {
			if (l.name == label) return cast(uint)l.offset;
		}
		return -1;
	}

	// # - Label
	// @ - Reference/Register
	// TODO: * - Address

	uint getSyscall(string t) {
		if (t.startsWith("#")) {
			foreach(i; 0 .. syscalls.length) {
				if (syscalls[i].name.toLower == t[1..$].toLower) 
					return cast(uint)i;
			}
			throw new Exception("syscall "~t~" not found!");
		}
		if (t.startsWith("@")) {
			return to!uint(t[1..$]);
		}
		return to!uint(t);
	}

	uint getVal(Label[] labels, size_t owner_offset, string t) {
		if (t.startsWith("#")) {
			LabelRef r = {t[1..$], owner_offset, code.length};
			labelRefs ~= r;
			return 0;
		}
		if (t.startsWith("@")) {
			t = t[1..$];
		}
		if (t.startsWith("0x")) {
			return to!uint(t[2..$], 16);
		}
		return to!uint(t);
	}

	OpCode getOp(string name) {
		return to!OpCode(name.toUpper);
	}

	DBGOpCode getDBGOp(string name) {
		return to!DBGOpCode(name.toUpper);
	}

	void printLabels() {
		writeln("Labels:");
		foreach(Label l; labels) {
			writeln("\t", l.name, "@", l.offset);
		}
	}
}

public string binToASMDESC(ubyte[] data) {
	Instruction[] instructions = (cast(Instruction*)data)[0..data.length/Instruction.sizeof];
	string oi = "";
	int line = 0;
	foreach(Instruction i; instructions) {
		oi ~= "\t" ~ to!string(line) ~ "\t" ~ to!string(i.opCode) ~ " " ~ to!string(i.data[0]) ~ " " ~ to!string(i.data[1]) ~ "\n";
		line++;
	}
	return oi;
}