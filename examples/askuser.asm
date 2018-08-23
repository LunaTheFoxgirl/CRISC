; read a single character

; Get safe area of memory, put address in to register 32.
scall #gsfm
pop @32
wordloop:
	; Call reader function
	push @32
	call #readf

	; write
	; Stack will be [<return val>, @32]
	push @32
	call #printf

jmp #wordloop

; halt execution
halt

readf:
	; memory area
	pop @1

	i_readfloop:
		; read key in to status buffer
		scall #rdc
		pop @0xFF

		; Store in memory.
		str @0xFF @1

		; add 4 to count.
		add 4 @1

	jmpneq #i_readfloop 10

	; Push length to stack
	push @1
	
	; return
	ret

printf:

	; string pointer
	pop @0xFF

	; string size
	pop @1

	i_printfloop:
		; load character to status register
		ldr @0xFF @0x0
		
		; print the character
		push @0x0
		scall #prtc

		; add 1 to counter.
		add 4 @0xFF

		jmpseq #i_printfloop @1

	; returns nothing.
	ret
