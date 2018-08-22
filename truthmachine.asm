; Truth machine

; Change value (1) to 0 for other state
mov 1 @0xFF

loop:
	; print value
	dbg PRT_REG @0xFF

; loop if register 0xFF is 1
jmpeq #loop 1

; halt execution.
halt
