LAB segment
		ASSUME CS: LAB, DS: LAB, ES: NOTHING, SS: NOTHING
		org 100h

START: jmp BEGIN

    ;DATA

AVL_MEMORY_INFO     db  "Available memory: $"
EXT_MEMORY_INFO     db  "Extended memory: $"

MCB_NUM_INFO 		db  "MCB number: $"
AREA_SIZE_INFO 		db  "    Area size: $"

END_LINE 			db  0Dh, 0Ah, "$"
KBYTES              db  " kbytes", 0Dh, 0Ah, "$"

OWNER_INFO 			db  0Dh, 0Ah, "Block is $"
OWNER_FREE 			db  " free$"
OWNER_XMS 			db  " OS XMS UMB$"
OWNER_TM 			db  " driver's top memory$"
OWNER_DOS 			db  " MS DOS$"
OWNER_386CB 		db  " busy by 386MAX UMB$"
OWNER_386B 			db  " blocked by 386MAX$"
OWNER_386 			db  " 386MAX UMB$"


    ; There is some CUSTOM procedures...

PRINT_STRING 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
	ret
PRINT_STRING 	ENDP

KBYTES_PRINT    PROC    near
        push    DX
        mov     DX, offset KBYTES
        call    PRINT_STRING
        pop     DX
    ret
KBYTES_PRINT    ENDP
        
DEC_WORD_PRINT 	PROC ; IN: AX
		push 	AX
		push 	CX
		push	DX
		push	BX

		mov 	BX, 10
		xor 	CX, CX
	NUM:
		div 	BX
		push	DX
		xor 	DX, DX
		inc 	CX
		cmp 	AX, 0h
		jnz 	NUM
		
		
	PRINT_NUM:
		pop 	DX
		or 		DL, 30h
		mov 	AH, 02h
		int 	21h
		loop 	PRINT_NUM
	
		pop 	BX
		pop 	DX
		pop 	CX
		pop 	AX
	ret
DEC_WORD_PRINT 	ENDP

HEX_BYTE_PRINT	PROC
		push 	AX
		push 	BX
		push 	DX
	
		mov 	AH, 0
		mov 	BL, 10h
		div 	BL
		mov 	DX, AX
		mov 	AH, 02h
		cmp 	DL, 0Ah
		jl 		PRINT
		add 	DL, 07h
	PRINT:
		add 	DL, '0'
		int 	21h;
		
		mov 	DL, DH
		cmp 	DL, 0Ah
		jl 		PRINT_EXT
		add 	DL, 07h
	PRINT_EXT:
		add 	DL, '0'
		int 	21h;
	
		pop 	DX
		pop 	BX
		pop 	AX
	ret
HEX_BYTE_PRINT	ENDP

HEX_WORD_PRINT	PROC
		push AX
		push AX

		mov AL, AH
		call HEX_BYTE_PRINT
		pop AX
		call HEX_BYTE_PRINT
		pop AX
	ret
HEX_WORD_PRINT	ENDP

FREE_MEM 	PROC
		push 	AX
		push 	BX
		push 	DX
		
		mov 	BX, offset PROG_END
		add 	BX, 100h
		shr 	BX, 1
		shr 	BX, 1
		shr 	BX, 1
		shr 	BX, 1 ; to paragraph
		mov 	AH, 4Ah
		int 	21h

		pop 	DX
		pop 	BX
		pop 	AX
	ret
FREE_MEM	 ENDP

ADD_MEM     PROC
		push    AX
		push    BX
		push    DX
	
		mov     BX, 1000h
		mov     AH, 48h
		int     21h

		pop     DX
		pop     BX
		pop     AX
	ret
ADD_MEM      ENDP

    ; here is the action...

PRINT_AVL_MEMORY 	PROC NEAR
	    push    AX
	    push    BX
	    push    DX
	    push    SI

	    xor     AX, AX
		int 	12h
		
	    mov     DX, offset AVL_MEMORY_INFO
	    call    PRINT_STRING
		xor		DX, DX
	    call    DEC_WORD_PRINT
        call    KBYTES_PRINT

	    pop     SI
	    pop     DX
	    pop     BX
	    pop     AX
	ret
PRINT_AVL_MEMORY 	ENDP

PRINT_EXT_MEMORY 	PROC NEAR
		push 	AX
		push 	BX
		push 	DX
		push 	SI

		mov 	AL, 30h
		out 	70h, AL
		in 		AL, 71h 
		mov 	BL, AL 
		mov 	AL, 31h  
		out 	70h, AL
		in 		AL, 71h

		mov 	AH, AL
		mov 	AL, BL

        mov 	DX, offset EXT_MEMORY_INFO
		call 	PRINT_STRING
		xor		DX, DX
		call 	DEC_WORD_PRINT
        call    KBYTES_PRINT

		pop 	SI
		pop 	DX
		pop 	BX
		pop 	AX

	ret
PRINT_EXT_MEMORY 	ENDP

PRINT_MCB 		PROC
		push 	AX
		push 	BX
		push 	CX
		push 	DX
		push 	ES
		push 	SI
	
		mov 	AH, 52h
		int 	21h
		mov 	AX, ES:[BX-2]
		mov 	ES, AX
		xor 	CX, CX
	NEXT_MCB:
		inc 	CX
		mov 	DX, offset MCB_NUM_INFO
		push 	CX
		call 	PRINT_STRING
		mov 	AX, CX
		xor 	DX, DX
		call	DEC_WORD_PRINT
	OWNER_START:
		mov 	DX, offset OWNER_INFO
		call 	PRINT_STRING
		xor 	AX, AX
		mov 	AL, ES:[0h]
		push 	AX
		mov 	AX, ES:[1h]
		
		cmp 	AX, 0h
		je 		PRINT_FREE
		cmp 	AX, 6h
		je 		PRINT_XMS
		cmp 	AX, 7h
		je 		PRINT_TM
		cmp 	AX, 8h
		je 		PRINT_DOS
		cmp 	AX, 0FFFAh
		je 		PRINT_386CB
		cmp 	AX, 0FFFDh
		je 		PRINT_386B
		cmp 	AX, 0FFFEh
		je 		PRINT_386
		xor 	DX, DX
		call 	HEX_WORD_PRINT
		jmp 	AREA_SIZE_START
		
	PRINT_FREE:
		mov 	DX, offset OWNER_FREE
		jmp 	OWNER_END
	PRINT_XMS:
		mov 	DX, offset OWNER_XMS
		jmp 	OWNER_END
	PRINT_TM:
		mov 	DX, offset OWNER_TM
		jmp 	OWNER_END
	PRINT_DOS:
		mov 	DX, offset OWNER_DOS
		jmp 	OWNER_END
	PRINT_386CB:
		mov 	DX, offset OWNER_386CB
		jmp 	OWNER_END
	PRINT_386B:
		mov 	DX, offset OWNER_386B
		jmp 	OWNER_END
	PRINT_386:
		mov 	DX, offset OWNER_386
	OWNER_END:
		call 	PRINT_STRING
	
	AREA_SIZE_START:	
		mov 	DX, offset AREA_SIZE_INFO
		call 	PRINT_STRING
		mov 	AX, ES:[3h]
		mov 	BX, 10h
		mul 	BX
		call 	DEC_WORD_PRINT

		mov 	CX, 8
		xor 	SI, SI
		mov 	DX, offset END_LINE
		call 	PRINT_STRING

	LAST_BYTES_START:
		mov     DL, ES:[SI + 8h]
		mov     AH, 02h
		int     21h
		inc     SI
		loop    LAST_BYTES_START
		
		mov     AX, ES:[3h]
		mov     BX, ES
		add     BX, AX
		inc     BX
		mov     ES, BX
		pop     AX
		pop     CX
		cmp     AL, 5Ah
		je      ENDING
		mov     DX, offset END_LINE
		call    PRINT_STRING
		jmp     NEXT_MCB
	
	ENDING:
		pop     SI
		pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
PRINT_MCB 		ENDP

BEGIN:
        call    ADD_MEM
        call 	FREE_MEM
		
        
        call    PRINT_AVL_MEMORY
		call	PRINT_EXT_MEMORY
        call    PRINT_MCB

        xor     AL, AL
	    mov     AH, 4Ch
	    int     21h

    
	PROG_END:

LAB     ends
end     START