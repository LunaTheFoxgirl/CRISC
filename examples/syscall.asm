dbg SET_VEB 1
dbg SET_VSTK 0

mov 0xFFF @0x43

push 0x0
push 0x0A
push 0x21
push 0x44
push 0x48
push 0x52
push 0x4F
push 0x57
push 0x20
push 0x4F
push 0x4C
push 0x4C
push 0x45
push 0x48
push @0x43
call #saveString

pop @0x43

push @0x43
call #printString
halt

saveString:
	; address offset of string
	pop @0x0
	
	dbg PRT_REG @0x0

	i_strjumpbacksave:
				
		; character
		pop @0x1

		; print character value (debug)
		dbg PRT_REG @0x1

		; store at address.
		str @0x1 @0x0

		; add 1 to address ptr
		add 1 @0x0

		; move 0x01 to status register
		mov @0x1 @0xFF

	; jump back if no null terminator is found.
	jmpneq #i_strjumpbacksave 0
	
	; push offset to stack
	push @0x0

	; return
	ret

printString:
	; address of string in memory
	pop @0x00
	
	i_strjumpback:
		; Load from memory a character
		ldr @0x0 @0x1

		; push it to the stack
		push @0x1
		
		; call the print-character function
		scall #prtc

		; move 0x01 to status register
		mov @0x1 @0xFF

		; decrease read pointer.
		sub 1 @0x00

	; jump back if no null terminator is found.
	jmpneq #i_strjumpback 0

	; return.
	ret
	
