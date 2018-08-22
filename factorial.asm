; Set verbose debugging
dbg SET_VEB 1

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

	; push it back on to the stack for the later unwinding
	pushr 0xFF

	; Jump to factorial recursing if i >= 1
	jmpleq #factiter 1
		; return with unwound stack.
		dbg PRT_REG 0xFF
		ret
	
	factiter:

		; subtract 1 from N
		subc 1 0xFF
		dbg PRT_REG 0xFF

		; push to stack and recurse.
		pushr 0xFF
		call #fact

		; pop back to 0x00 and 0x01 register
		pop 0xFF
		pop 0x01
		dbg PRT_REG 0x01
		dbg PRT_REG 0xFF

		; multiply N by last factorial
		mul 0x01 0x00

		; push to stack and return.
		pushr 0x00
		ret
