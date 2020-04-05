CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

INTERRUPTION    PROC    FAR
        jmp     INT_START
    INT_DATA:
        INT_CODE        DW  3158h

        KEEP_IP 	DW  0
        KEEP_CS 	DW  0
		KEEP_PSP 	DW	0

		SYMB 		DB 	0
    
    INT_START:
		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
        push    ES
        push    DS

		mov 	AX, SEG SYMB
		mov 	DS, AX

		in 		AL, 60h
		cmp 	AL, 02h
		je 		OUT_S
		cmp 	AL, 03h
		je 		OUT_E
		cmp 	AL, 04h
		je 		OUT_C
		cmp 	AL, 05h
		je 		OUT_R
		cmp 	AL, 06h
		je 		OUT_E
		cmp 	AL, 07h
		je 		OUT_T

		pushf
		call 	DWORD PTR CS:KEEP_IP
		jmp 	INT_END
		
	OUT_S:
		mov		SYMB, 'S'
		jmp		PROCESSING_SYMB
	OUT_E:
		mov		SYMB, 'E'
		jmp		PROCESSING_SYMB
	OUT_C:
		mov		SYMB, 'C'
		jmp		PROCESSING_SYMB
	OUT_R:
		mov		SYMB, 'R'
		jmp		PROCESSING_SYMB
	OUT_T:
		mov		SYMB, 'T'
			
	PROCESSING_SYMB:
		in 		AL, 61h
		mov 	AH, AL
		or 		AL, 80h
		out 	61h, AL
		xchg	AL, AL
		out 	61h, AL
		mov 	AL, 20h
		out 	20h, AL
		
	WRITE_SYMB:
		mov 	AH, 05h
		mov 	CL, SYMB
		mov 	CH, 00h
		int 	16h
		or 		AL, AL
		jz 		INT_END
		
		mov 	AX, 0040h
		mov 	ES, AX
		mov 	AX, ES:[1Ah]
		mov 	ES:[1Ch], AX
		jmp 	WRITE_SYMB
		
	INT_END:	
		pop     DS
		pop     ES
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX
		mov 	AL, 20h
		out 	20h, AL
		IRET
	ret
INTERRUPTION    ENDP
    LAST_BYTE:

INT_CHECK       PROC
		push    AX
		push    BX
		push    SI
		
		mov     AH, 35h
		mov     AL, 09h
		int     21h
		mov     SI, offset INT_CODE
		sub     SI, offset INTERRUPTION
		mov     AX, ES:[BX + SI]
		cmp	    AX, INT_CODE
		jne     INT_CHECK_END
		mov     INT_LOADED, 1
		
	INT_CHECK_END:
		pop     SI
		pop     BX
		pop     AX
	ret
INT_CHECK       ENDP

INT_LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS

        mov     AH, 35h
		mov     AL, 09h
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg INTERRUPTION
		mov     DX, offset INTERRUPTION	
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop		DS

        mov     DX, offset LAST_BYTE
		mov     CL, 4h
		shr     DX, CL
		add		DX, 10Fh
		inc     DX
		xor     AX, AX
		mov     AH, 31h
		int     21h

        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
INT_LOAD        ENDP

INT_UNLOAD      PROC
        CLI
		push    AX
		push    BX
		push    DX
		push    DS
		push    ES
		push    SI
		
		mov     AH, 35h
		mov     AL, 09h
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset INTERRUPTION
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop 	DS
		
		mov 	AX, ES:[BX + SI + 4]
		mov 	ES, AX
		push 	ES
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h
		pop 	ES
		mov 	AH, 49h
		int 	21h
		
		STI
		
		pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX
		
	ret
INT_UNLOAD      ENDP

CL_CHECK        PROC
        push    AX
		push    ES

		mov     AX, KEEP_PSP
		mov     ES, AX
		cmp     byte ptr ES:[82h], '/'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[83h], 'u'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[84h], 'n'
		jne     CL_CHECK_END
		mov     UN_CL, 1
		
	CL_CHECK_END:
		pop     ES
		pop     AX
		ret
CL_CHECK        ENDP

PRINT_STRING    PROC    NEAR
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
    ret
PRINT_STRING    ENDP

MAIN PROC
		push    DS
		xor     AX, AX
		push    AX
		mov     AX, DATA
		mov     DS, AX
		mov     KEEP_PSP, ES
		
		call    INT_CHECK
		call    CL_CHECK
		cmp     UN_CL, 1
		je      UNLOAD
		mov     AL, INT_LOADED
		cmp     AL, 1
		jne     LOAD
		mov     DX, offset WAS_LOADED_INFO
		call    PRINT_STRING
		jmp     MAIN_END
	LOAD:
		call    INT_LOAD
		jmp     MAIN_END
	UNLOAD:
		cmp     INT_LOADED, 1
		jne     NOT_EXIST
		call    INT_UNLOAD
		jmp     MAIN_END
	NOT_EXIST:
		mov     DX, offset NOT_LOADED_INFO
		call    PRINT_STRING
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENDS

DATA    SEGMENT
	WAS_LOADED_INFO     DB  "Interruption was already loaded", 10, 13,"$"
	NOT_LOADED_INFO		DB  "Interruption is not loaded", 10, 13,"$"
    INT_LOADED          DB  0
    UN_CL               DB  0
DATA    ENDS

END 	MAIN