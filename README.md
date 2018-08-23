# CRISC
Clipsey's Reduced Instruction Set Computing virtual toy processor and assembler.

## What does CRISC do?
CRISC is a single-file virtual CPU and assembler for a small toy architecture I made because i was bored.

Please don't make any serious applications with this, (neither can you, really.)

# Building

To build CRISC, you need to have the DMD compiler installed.

Run
```
make
sudo make install
```

To build and install CRISC.

# Usage

To assemble an crisc assembly file, use `criscasm`, for running a crisc binary `criscexec`.


# Notes

## How do you get addresses from labels?
To get the address of an label suffix it with #, for example:
`jmpc #myJumpoint`

## How do you declare variables and create strings?
You can't yet.

## Conditional execution
In CRISC, to do conditional execution you first have to move the value you want to test to the status buffer (0xFF)
then, you can compared values, const values and register values are the current supported options.

## Instruction Set

**DO NOTE** `criscasm` will automatically infer which mode you are going to use. So if you are working with registers, remember to suffix arguments with @ for registers/addresses.

**Instruction**|**Input A**|**Input B**|** Description**
:-----:|:-----:|:-----:|:-----:
HALT| | |Halts the execution of the program
MOV|REG A|REG B|Moves register A to register B
MOVC|CONST A|REG B|Moves const A to register B
ADD|REG A|REG B|Adds register A to register B
ADDC|CONST A|REG B|Adds const A to register B
SUB|REG A|REG B|Subtracts register A to register B
SUBC|CONST A|REG B|Subtracts const A to register B
MUL|REG A|REG B|Multiplies register A to register B
MULC|CONST A|REG B|Multiplies const A to register B
DIV|REG A|REG B|Divides register A to register B
DIVC|CONST A|REG B|Divides const A to register B
JMP|ADDRESS A| |Jumps to address A
JMPEQ|ADDRESS A|REG B|Jumps to address A if B is equal to value in status register
JMPNEQ|ADDRESS A|REG B|Jumps to address A if B is not equal to value in status register
JMPLEQ|ADDRESS A|REG B|Jumps to address A if B is larger than or equal to value in status register
JMPSEQ|ADDRESS A|REG B|Jumps to address A if B is smallerthan or equal to value in status register
JMPC|CONST ADDRESS A| |Jumps to address A
JMPEQC|ADDRESS A|CONST B|Jumps to address A if B is equal to value in status register
JMPNEQC|ADDRESS A|CONST B|Jumps to address A if B is not equal to value in status register
JMPLEQC|ADDRESS A|CONST B|Jumps to address A if B is larger than or equal to value in status register
JMPSEQC|ADDRESS A|CONST B|Jumps to address A if B is smallerthan or equal to value in status register
LDR|REG A|ADDRESS B|Load memory from address B in to register A
LDRC|CONST A|ADDRESS B|Load memory from const B in to register A
STR|REG A|ADDRESS B|Store memory from register A in to address B (in memory)
STRC|CONST A|ADDRESS B|Store memory from const A in to address B (in memory)
CALL|ADDRESS A| |Call address A
PUSH|REG A| |Push value from register A to stack
PUSHC|CONST A| |Push constant value to stack
POP|REG A| |Pop value from stack to register A
RET| | |Return from subroutine
DBG|DBG OPTION A|CONST B|Set debugging options
