; Set verbose debugging
dbg SET_VEB 0
dbg SET_VSTK 1

; Push 3 to the stack (origin value)
push 3

; Call factorial function
call #fact

; Print result.
pop 0x0
dbg PRT_REG 0x0

; End program here.
halt

; Factorial function (recursive)
fact:
	; pop off stack, to 0xFF register
	pop 0xFF

	; Jump to factorial recursing if i >= 1
	jmpleq #factiter 1

		push 1

		; return with unwound stack.
		ret
	
	factiter:
		; push it back on to the stack for the later unwinding
		pushr 0xFF
	
		; subtract 1 from N
		subc 1 0xFF

		; push to stack and recurse.
		pushr 0xFF
		call #fact

		; Print stack (debugging)
		; pop back to 0x00 and 0x01 register
		pop 0x00
		pop 0x01

		; multiply N by last factorial
		mul 0x01 0x00
		dbg PRT_REG 0x0
		dbg PRT_REG 0x1

		; push to stack and return.
		pushr 0xFF
		pushr 0x00
		ret
