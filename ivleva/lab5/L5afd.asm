ASSUME CS:CODE, DS:DATA, SS:ASTACK

CODE SEGMENT

INTERRUPT PROC FAR
        jmp INT_START

    INT_DATA:
        INT_STACK 	dw  128 dup(0)
        INT_CODE 	dw  0903h
        KEEP_IP  	dw  0
        KEEP_CS  	dw  0
        KEEP_PSP 	dw  0
        KEEP_SS 	dw  0
        KEEP_SP 	dw  0
        SYMB 		db  0
        TSS 		dw  0

    INT_START:
        mov 	KEEP_SS, SS
        mov 	KEEP_SP, SP
        mov 	TSS, seg INTERRUPT
        mov 	SS, TSS
        mov 	SP, offset INT_STACK
        add 	SP, 256

        push 	AX
        push 	BX
        push 	CX
        push 	DX
        push 	SI
        push 	ES
        push 	DS

        mov 	AX, SEG INTERRUPT
        mov 	DS, AX

        in 		AL, 60h
		cmp 	AL, 10h
		je 		OUT_P
		cmp 	AL, 11h
		je 		OUT_R
		cmp 	AL, 12h
		je 		OUT_I
		cmp 	AL, 13h
		je 		OUT_M
		cmp 	AL, 14h
		je 		OUT_I
		cmp 	AL, 15h
		je 		OUT_T
		cmp 	AL, 16h
		je 		OUT_E
		cmp 	AL, 17h
		je 		OUT_L
		cmp 	AL, 18h
		je 		OUT_A
		cmp 	AL, 19h
		je 		OUT_B
		cmp 	AL, 1Ah
		je 		OUT_U
		
		pushf
		call 	DWORD PTR CS:KEEP_IP
		jmp 	INT_END
		
	OUT_P:
		mov		SYMB, 'Q'
		jmp		PROCESSING_SYMB
	OUT_R:
		mov		SYMB, 'U'
		jmp		PROCESSING_SYMB
	OUT_I:
		mov		SYMB, 'I'
		jmp		PROCESSING_SYMB
	OUT_M:
		mov		SYMB, 'T'
		jmp		PROCESSING_SYMB
	OUT_T:
		mov		SYMB, 'A'
		jmp		PROCESSING_SYMB
	OUT_E:
		mov		SYMB, 'U'
		jmp		PROCESSING_SYMB
	OUT_L:
		mov		SYMB, 'D'
		jmp		PROCESSING_SYMB
	OUT_A:
		mov		SYMB, 'I'
		jmp		PROCESSING_SYMB
	OUT_B:
		mov		SYMB, 'O'
		jmp		PROCESSING_SYMB
	OUT_U:
		mov		SYMB, 'P'

    PROCESSING_SYMB:
        in 		AL, 61h
        mov 	AH, AL
        or 		AL, 80h
        out 	61h, AL
        xCHg 	AL, AL
        out 	61h, AL
        mov 	AL, 20h
        out 	20h, AL

    INT_PRINT:
        mov 	AH, 05h
        mov 	CL, SYMB
        mov 	CH, 00h
        int 	16h
        or 		AL, AL
        jz 		INT_END

        mov 	AX, 0040h
        mov 	ES, AX
        mov 	AX, ES:[1AH]
        mov 	ES:[1CH], AX
        jmp 	INT_PRINT

    INT_END:
        pop 	DS
        pop 	ES
        pop 	SI
        pop 	DX
        pop 	CX
        pop 	BX
        pop 	AX

        mov 	SS, KEEP_SS
        mov 	SP, KEEP_SP

        mov 	AL, 20h
        out 	20h, AL
        IRET
INTERRUPT ENDP
    LAST_BYTE:



LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS

        mov     AH, 35h
		mov     AL, 09h
		int     21h
        mov     KEEP_IP, BX
		mov     KEEP_CS, ES

        mov     DX, offset INTERRUPT
        mov     AX, seg INTERRUPT
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop		DS

        mov     DX, offset LAST_BYTE
        add     DX, 100h
		mov     CL, 4h
		shr     DX, CL
		inc     DX
		mov     AH, 31h
		int     21h

        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX

	    ret
LOAD        ENDP



UNLOAD      PROC
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
        sub     SI, offset INTERRUPT
		mov 	DX, ES:[BX + SI]
        mov 	SI, offset KEEP_CS
        sub     SI, offset INTERRUPT
		mov 	AX, ES:[BX + SI]

		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop 	DS

        mov 	SI, offset KEEP_PSP
        sub     SI, offset INTERRUPT
        mov 	AX, ES:[BX + SI]
        mov     ES, AX
        push    ES
        mov 	AX, ES:[2CH]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h

        pop     ES
        mov 	AH, 49h
		int 	21h

        pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX

		sti
	    ret
UNLOAD      ENDP



INT_CHECK       PROC
		push    AX
		push    BX
		push    SI

		mov     AH, 35h
		mov     AL, 09h
		int     21h

		mov     SI, offset INT_CODE
        sub     SI, offset INTERRUPT
		mov     AX, ES:[BX + SI]
		cmp	    AX, INT_CODE
		jne     INT_CHECK_END

        mov     CL, UN_CHECK
		add     CL, 1
		mov     UN_CHECK, CL

	INT_CHECK_END:
		pop     SI
		pop     BX
		pop     AX

	    ret
INT_CHECK       ENDP



TAIL_CHECK        PROC

		push    AX
		cmp     byte ptr ES:[82h], '/'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[83h], 'U'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[84h], 'N'
		jne     CL_CHECK_END
		mov     AL, UN_CHECK
		add     AL, 2
		mov     UN_CHECK, AL

	CL_CHECK_END:
		pop     AX
		ret
TAIL_CHECK        ENDP


PRINT_STRING    PROC    NEAR
        push    AX
        mov     AH, 09h
        int     21h

        mov     DX, offset ENDL
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

        mov    	UN_CHECK, 0
        call   	TAIL_CHECK
	    call   	INT_CHECK

		cmp 	UN_CHECK, 0
		je 		INT_LOAD
		cmp 	UN_CHECK, 1
		je 		INT_LOAD_AGAIN
		cmp 	UN_CHECK, 2
		je 		INT_UNLOAD_AGAIN
		jmp 	INT_UNLOAD ; 11

	INT_LOAD:
        mov     DX, offset SUCCESS_LOAD_STRING
        cALl    PRINT_STRING
		cALl    LOAD
		jmp     MAIN_END

	INT_LOAD_AGAIN:
		mov     DX, offset ERR_LOAD_STR
        cALl    PRINT_STRING
		jmp     MAIN_END

	INT_UNLOAD_AGAIN:
		mov     DX, offset ERR_UNLOAD
		cALl    PRINT_STRING
		jmp     MAIN_END

	INT_UNLOAD:
		cALl    UNLOAD
        mov     DX, offset UNLOAD_STR
		cALl    PRINT_STRING
		jmp     MAIN_END

	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4CH
		int 	21h
	MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    dw  128 dup(0)
ASTACK  ENDS

DATA SEGMENT
    SUCCESS_LOAD_STRING db "Interruption loaded", '$'
    ERR_LOAD_STR 		db "Interruption was loaded before", '$'
    UNLOAD_STR 			db "Interruption unloaded", '$'
    ERR_UNLOAD 			db "Interruption was not loaded before", '$'
    ENDL 				db 10, 13, '$'
    UN_CHECK 			db  0;
DATA ENDS

END 	MAIN