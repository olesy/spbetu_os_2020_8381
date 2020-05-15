TesTPC segment
		ASSUME CS: TesTPC, DS: TesTPC, es: NOTHING, SS: NOTHING
		org 100h

START: jmp BEGIN

available_memory_str db  'Available memory(kb): $'
extended_memory_str db  'Extended memory(kb): $'
mcb_str db 'Memory control blocks: ', 13, 10, '$'
owner_str db '        Owner: $' 
owner_free_str db 'free', 13, 10, '$'
owner_xms_str db 'OS XMS UMB', 13, 10, '$'
owner_top_memory_str db 'Top memory', 13, 10, '$'
owner_msdos_str db 'MS DOS', 13, 10, '$'
owner_386UMB_str db '386Max UMB', 13, 10, '$'
blocked_386Max_str db 'Blocked by 386Max', 13, 10, '$'
busy_386UMB_str db 'Busy by 386Max UMB', 13, 10, '$'
area_size_str db 'Area size(b): $'
number_str db 'Number: $'
new_line_str db 13, 10, '$'

print 	PROC	near
	push 	ax
	mov 	ah, 09h
	int		21h
	pop 	ax
	ret
print 	ENDP
        
DEC_WORD_PRINT 	PROC ; IN: ax
		push 	ax
		push 	cx
		push	dx
		push	bx

		mov 	bx, 10
		xor 	cx, cx
	NUM:
		div 	bx
		push	dx
		xor 	dx, dx
		inc 	cx
		cmp 	ax, 0h
		jnz 	NUM
		
		
	PRINT_NUM:
		pop 	dx
		or 		dl, 30h
		mov 	ah, 02h
		int 	21h
		loop 	PRINT_NUM
	
		pop 	bx
		pop 	dx
		pop 	cx
		pop 	ax
	ret
DEC_WORD_PRINT 	ENDP

HEX_BYTE_PRINT	PROC
		push 	ax
		push 	bx
		push 	dx
	
		mov 	ah, 0
		mov 	bl, 10h
		div 	bl
		mov 	dx, ax
		mov 	ah, 02h
		cmp 	dl, 0ah
		jl 		PRINTING
		add 	dl, 07h
	PRINTING:
		add 	dl, '0'
		int 	21h;
		
		mov 	dl, DH
		cmp 	dl, 0ah
		jl 		PRINT_EXT
		add 	dl, 07h
	PRINT_EXT:
		add 	dl, '0'
		int 	21h;
	
		pop 	dx
		pop 	bx
		pop 	ax
	ret
HEX_BYTE_PRINT	ENDP

HEX_WORD_PRINT	PROC
		push ax
		push ax

		mov al, ah
		call HEX_BYTE_PRINT
		pop ax
		call HEX_BYTE_PRINT
		pop ax
	ret
HEX_WORD_PRINT	ENDP

BEGIN:
MEMORY_CLEARING:
	mov BX, offset PROGRAMM_END_POINT
	add BX, 100h
	shr BX, 1
	shr BX, 1
	shr BX, 1
	shr BX, 1 ; to paragraph
	mov AH, 4Ah
	int 21h

AVAILABLE_MEMORY:
	mov ax, 0
	int 	12h ; ax = размер  используемой памяти
	mov     dx, offset available_memory_str
	call    print
	xor		dx, dx
	call    DEC_WORD_PRINT
	mov dx, offset new_line_str
	call print

EXTENED_MEMORY:
	mov 	al, 30h
	out 	70h, al
	in 		al, 71h 
	mov 	bl, al 
	mov 	al, 31h  
	out 	70h, al
	in 		al, 71h

	mov 	ah, al
	mov 	al, bl

	mov 	dx, offset extended_memory_str
	call 	print
	xor		dx, dx
	call 	DEC_WORD_PRINT
	mov dx, offset new_line_str
	call print
	mov dx, offset new_line_str
	call print
	mov dx, offset mcb_str
	call print
	
LIST_OF_MCB:
		mov 	ah, 52h
		int 	21h
		mov 	ax, es:[bx-2]
		mov 	es, ax
		xor 	cx, cx
	NEXT_MCB:
		inc 	cx
		mov 	dx, offset number_str
		push 	cx
		call 	print
		mov 	ax, cx
		xor 	dx, dx
		call	DEC_WORD_PRINT
		
	OWNER_PRINTING:
		mov 	dx, offset owner_str
		call 	print
		xor 	ax, ax
		mov 	al, es:[0h]
		push 	ax
		mov 	ax, es:[1h]
		
		cmp 	ax, 0h
		je 		OWNER_FREE
		cmp 	ax, 6h
		je 		OWNER_XMS
		cmp 	ax, 7h
		je 		OWNER_TOP_MEMORY
		cmp 	ax, 8h
		je 		OWNER_MSDOS
		cmp 	ax, 0FFFah
		je 		BUSY_386UMB
		cmp 	ax, 0FFFDh
		je 		BLOCKED_386Max
		cmp 	ax, 0FFFEh
		je 		OWNER_386UMB
		xor 	dx, dx
		call 	HEX_WORD_PRINT
		mov dx, offset new_line_str
		call print
		jmp 	AREA_SIZE
		
	OWNER_FREE:
		mov 	dx, offset owner_free_str
		jmp 	OWNER_PRINTING_END
	OWNER_XMS:
		mov 	dx, offset owner_xms_str
		jmp 	OWNER_PRINTING_END
	OWNER_TOP_MEMORY:
		mov 	dx, offset owner_top_memory_str
		jmp 	OWNER_PRINTING_END
	OWNER_MSDOS:
		mov 	dx, offset owner_msdos_str
		jmp 	OWNER_PRINTING_END
	BUSY_386UMB:
		mov 	dx, offset busy_386UMB_str
		jmp 	OWNER_PRINTING_END
	BLOCKED_386Max:
		mov 	dx, offset blocked_386Max_str
		jmp 	OWNER_PRINTING_END
	OWNER_386UMB:
		mov 	dx, offset owner_386UMB_str
	OWNER_PRINTING_END:
		call 	print
	
	AREA_SIZE:	
		mov 	dx, offset area_size_str
		call 	print
		mov 	ax, es:[3h]
		mov 	bx, 10h
		mul 	bx
		call 	DEC_WORD_PRINT

		mov 	cx, 8
		xor 	si, si
		mov 	dx, offset new_line_str
		call 	print

	LAST_INFORMATION:
		mov     dl, es:[si + 8h]
		mov     ah, 02h
		int     21h
		inc     si
		loop    LAST_INFORMATION
		
		mov     ax, es:[3h]
		mov     bx, es
		add     bx, ax
		inc     bx
		mov     es, bx
		pop     ax
		pop     cx
		cmp     al, 5ah
		je      ENDING
		mov     dx, offset new_line_str
		call    print
		jmp     NEXT_MCB


ENDING:
	pop di
	pop si
	pop dx
	pop	ax	
	mov ah, 4ch
	int	21h
	ret 
PROGRAMM_END_POINT:

TesTPC    ends
end     START