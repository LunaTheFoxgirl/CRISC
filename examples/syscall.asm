; Hello world (no memory operations)

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

; call printstring
call #printString

; Halt/end execution
halt

printString:
	i_strjumpback:
		; Load from stack a character, then push it back so the syscall can print it.
		pop @0x1
		push @0x1
		
		; call the print-character function
		scall #prtc

		; move address 0x1 (the character) to status register
		mov @0x1 @0xFF

	; jump back if no null terminator is found.
	jmpneq #i_strjumpback 0

	; return.
	ret
	
