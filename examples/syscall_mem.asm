dbg SET_VEB 0
dbg SET_VSTK 0

push 0x0  ; \0
push 0x0A ; \n
push 0x21 ; !
push 0x44 ; D
push 0x4C ; L
push 0x52 ; R
push 0x4F ; O
push 0x57 ; W
push 0x20 ; <SPACE>
push 0x4F ; O
push 0x4C ; L
push 0x4C ; L
push 0x45 ; E
push 0x48 ; H

push 1400
call #saveString

push 1400
call #printString

halt

saveString:
	; address offset of string
	pop @0x0

	i_strjumpbacksave:
				
		; character
		pop @0x1
		; store at address.
		str @0x1 @0x0

		; add 1 to address ptr
		add 8 @0x0

		; move 0x01 to status register
		mov @0x1 @0xFF

	; jump back if no null terminator is found.
	jmpneq #i_strjumpbacksave 0

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

		; increase read pointer.
		add 8 @0x00

	; jump back if no null terminator is found.
	jmpneq #i_strjumpback 0

	; return.
	ret
	
