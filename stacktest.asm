
mov 1 @0x00
mov 1 @0xFF
multLoop:
	mul 2 @0x00
	add 1 @0xFF
	push @0x00
jmpseq #multLoop 26

; print the call stack
dbg PRT_CSTK 0

; print the data stack
dbg PRT_DSTK 0

halt
