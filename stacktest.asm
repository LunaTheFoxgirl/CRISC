
movc 1 0x00
movc 1 0xFF
multLoop:
	mulc 2 0x00
	addc 1 0xFF
	pushr 0x00
jmpseq #multLoop 26

; print the call stack
dbg PRT_CSTK 0

; print the data stack
dbg PRT_DSTK 0

halt
