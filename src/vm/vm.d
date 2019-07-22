module vm.vm;

/**
    Bitmask for Address-addressing mode
*/
enum ModeAddress =      0b10001000_00000000;

/**
    Bitmask for Register-addressing mode
*/
enum ModeRegister =     0b01000100_00000000;

/**
    Bitmask for Const-addressing mode
*/
enum ModeConst =        0b00100010_00000000;

/**
    Bitmask for Input-addressing mode
*/
enum ModeInput =        0b00010000_00000000;

/**
    Bitmask for Output-addressing mode
*/
enum ModeOutput =       0b00000001_00000000;

/**
    The status of the VM
*/
enum Status : ubyte {
    /// Wether the VM is running
    Running  = 0b00000001,

    /// Wether a failure caused the VM to stop running
    Failure  = 0b00000010,

    /// Wether a failure from an external library caused the VM to stop running
    ExtFail  = 0b00000100,

    /// Wether a invalid instruction caused the VM to stop running.
    InstrInv = 0b01000000,

    /// Wether a HALT instruction caused the VM to stop running.
    InstrHA  = 0b10000000
}

enum : ubyte {
    /// Move
    MOV   = 0b00000001,

    /// Move Byte
    MOVB  = 0b00000001,

    /// Move Short
    MOVS  = 0b00000010,

    /// Move Int
    MOVI  = 0b00000011,

    /// Move Long
    MOVL  = 0b00000100,



    /// Add 
    ADD   = 0b00000101,

    /// Add Byte
    ADDB  = 0b00000101,

    /// Add Short 
    ADDS  = 0b00000110,

    /// Add Int 
    ADDI  = 0b00000111,

    /// Add Long 
    ADDL  = 0b00001000, 



    /// Subtract 
    SUB   = 0b00001001,
    
    /// Subtract Byte
    SUBB  = 0b00001001, 

    /// Subtract Short
    SUBS  = 0b00001010,

    /// Subtract Int 
    SUBI  = 0b00001011,

    /// Subtract Long 
    SUBL  = 0b00001100, 



    /// Multiply 
    MUL   = 0b00001101,

    /// Multiply Byte
    MULB  = 0b00001101,

    /// Multiply Short 
    MULS  = 0b00001110,

    /// Multiply Int 
    MULI  = 0b00001111,

    /// Multiply Long 
    MULL  = 0b00010000, 



    /// Divide 
    DIV   = 0b00010001,

    /// Divide Byte
    DIVB  = 0b00010001,

    /// Divide Short 
    DIVS  = 0b00010010,

    /// Divide Int 
    DIVI  = 0b00010011,

    /// Divide Long 
    DIVL  = 0b00010100, 



    /// Shift Left 
    SHL   = 0b00010101,

    /// Shift Left Byte
    SHLB  = 0b00010101,

    /// Shift Left Short 
    SHLS  = 0b00010110, 

    /// Shift Left Int
    SHLI  = 0b00010111,

    /// Shift Left Long 
    SHLL  = 0b00011000, 



    /// Shift Right 
    SHR   = 0b00011001,

    /// Shift Right Byte
    SHRB  = 0b00011001, 


    /// Shift Right Short
    SHRS  = 0b00011010, 

    /// Shift Right Int
    SHRI  = 0b00011011,

    /// Shift Right Long 
    SHRL  = 0b00011100, 



    /// Add Float
    ADDF  = 0b00011101,

    /// Subtract Float
    SUBF  = 0b00011110,

    /// Multiply Float
    MULF  = 0b00011111,

    /// Divide Float
    DIVF  = 0b00100000,



    /// Float to Int
    FTI   = 0b00100001,

    /// Int to Float
    ITF   = 0b00100010,



    /// Compare
    CMP   = 0b00100011,

    /// Compare Floats
    CMPF  = 0b00100100,

    /// Jump
    JMP   = 0b00100101,

    /// Jump Zero
    JZ    = 0b00100110,
    
    /// Jump Not Zero
    JNZ   = 0b00100111,
    
    /// Jump Sign
    JS    = 0b00101000,
    
    /// Jump Not Sign
    JNS   = 0b00101001,
    
    /// Jump Carry
    JC    = 0b00101010,
    
    /// Jump Not Carry
    JNC   = 0b00101011,
    
    /// Jump Equal
    JE    = 0b00101100,
    
    /// Jump Not Equal
    JNE   = 0b00101101,
    
    /// Jump Above
    JA    = 0b00101110,
    
    /// Jump Above Equal
    JAE   = 0b00101111,

    /// Jump Below
    JB    = 0b00110000,
    
    /// Jump Below Equal
    JBE   = 0b00110001,

    
    /// Push 
    PUSH  = 0b00110010,
    
    /// Push Byte
    PUSHB = 0b00110011,
    
    /// Push Short
    PUSHS = 0b00110100,
    
    /// Push Int
    PUSHI = 0b00110101,
    
    /// Push Long
    PUSHL = 0b00110110,
    
    /// Push Float
    PUSHF = 0b00110111,

    /// Pop
    POP   = 0b00111000,

    /// Call subroutine
    CALL  = 0b00111001,

    /// Return from subroutine
    RET   = 0b00111010,

    /// Load Data
    LDR   = 0b00111011,

    /// Store Data
    STR   = 0b00111100,

    /// Procedure Call
    PCALL = 0b00111101,


    /// Halt execution
    HALT  = 0b11111111
}

/**
    An OPCode
*/
union OPCode {
    /**
        Partial OPCode, split in half
        0 = Addressing Mode
        1 = Instruction
    */
    ubyte[2] partial;

    /**
        Full instruction
    */
    short    full;
}

/**
    Integer register
*/
union RegInt {
    /**
        byte register
    */
    ubyte gb;

    /**
        short register
    */
    ushort gs;

    /**
        int register
    */
    uint gi;

    /**
        long register
    */
    ulong gl;

    this(ulong v) {
        gl = v;
    }
}

alias InterruptHandler = void function(VM* vm);
alias ProcCallHandler = void function(ubyte[] stack);

/**
    The virtual machine the instructions run in
*/
struct VM {
private:
    ubyte[] program;
    InterruptHandler[] interrupts;
    ProcCallHandler[] procedureCalls;

    Status vmStatus;
    bool halted;

    void statusset(Status status) {
        vmStatus |= status;
    }

    void statusclear() {
        vmStatus = 0;
    }

    void statusunset(Status status) {
        vmStatus &= ~(status);
    }

    void resetState() {

        // Step 1. Reset all the registers to 0 values to avoid old data messing with the program

        gpRegInt[0] = RegInt(0u);
        gpRegInt[1] = RegInt(0u);
        gpRegInt[2] = RegInt(0u);
        gpRegInt[3] = RegInt(0u);
        gpRegInt[4] = RegInt(0u);

        gpRegFloat32[0] = 0f;
        gpRegFloat32[1] = 0f;
        gpRegFloat64[0] = 0f;
        gpRegFloat64[1] = 0f;
        stk = 0;
        btk = 0;
        sts = 0;
        ins = 0;

        fwd[0] = 0u;
        fwd[1] = 0u;
        fwd[2] = 0u;
        fwd[3] = 0u;

        // Step 2. Prepare the "processor" state

        halted = false;
    }

    /**
        Reads the next instruction
    */
    OPCode fetch() {
        scope(exit) ins += OPCode.sizeof;
        return cast(OPCode)(program[ins..ins+OPCode.sizeof]);
    }

    /**
        Process/Execute instruction
    */
    void process(OPCode opcode) {
        switch(opcode) {
            case HALT:
                // HALT: Halts the CPU
                halted = true;
                statusset(Status.InstrHA);
                return;
            
                
            default:
                // DEFAULT: Halt for invalid instruction, as it hasn't been implemented yet it seems.
                halted = true;
                statusset(Status.InstrInv);
                return;
        }
    }

public:

    /// Gets the VM status of selected type
    bool statusquery(Status status) {
        return (vmStatus & status) > 0;
    }

    /**
        General purpose int registers
        0-19
    */
    RegInt[5] gpRegInt;
    
    /**
        General purpose float registers
    */
    float[2] gpRegFloat32;

    /**
        General purpose double registers
    */
    double[2] gpRegFloat64;

    /**
        Stack pointer
    */
    ulong stk;

    /**
        Backup stack pointer
    */
    ulong btk;

    /**
        Status register
    */
    ulong sts;

    /**
        Instruction Counter
    */
    ulong ins;

    /**
        Forwarding pointers
    */
    ulong[4] fwd;

    /// Gets the VM Status
    Status status() {
        return vmStatus;
    }

    /// Run a peice of bytecode
    Status run(ubyte[] program) {
        scope(exit) statusunset(Status.Running);
        scope(failure) statusset(Status.ExtFail);
        statusclear();
        statusset(Status.Running);

        resetState();

        // Copy in the bytecode.
        this.program[] = program;

        // The execution loop.
        do { next(); } while(ins < program.length && !halted);
        return vmStatus;
    }

    void next() {
        OPCode opcode = fetch();
        process(opcode);
    }
}