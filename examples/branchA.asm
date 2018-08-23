; move 31 to register 1
mov 31 @0x1

; move 0 to register 0
mov 0 @0x0

; Loop begin
add_loop:

	; print value of register 0
	dbg PRT_REG @0x0

	; add 1 to register 0
	add 1 @0x0

	; move register 1 to 255
	mov @0x1 @0xFF

; loop if register 0's value is less than register 255's value.
jmpleq #add_loop @0x0

; Print value of register 0
dbg PRT_REG @0x0

; Print value of register 1
dbg PRT_REG @0xFF

; Halt execution.
halt
