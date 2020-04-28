DATA SEGMENT
    PSP_OFFSET  dw 0
    DTA         db 43 dup(0)
    OVL1_NAME   db "ovl1.ovl", 0
	OVL2_NAME   db "ovl2.ovl", 0
    PATH        db 100h dup(0)
    OVL_PARAM   dw 0
	OVL_ADRESS  dd 0
    OVL_OFFSET  dw 0
    OVL_POS     dw 0
    SIZE_ERROR_MSG      db 13, 10, "Size of the OVL wasn't get$"
    NOFILE_MSG          db 13, 10, "File wasn't found$"
    NOPATH_MSG          db 13, 10, "Path wasn't found$"
    ERROR_LOAD_MSG      db 13, 10, "Error while loading OVL$"

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACKK

PRINT_STRING 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
	ret
PRINT_STRING 	ENDP

MEMORY_FREE 	PROC
		lea 	BX, PROGEND
		mov 	AX, ES
		sub 	BX, AX
		mov 	CL, 4
		shr 	BX, CL
		mov 	AH, 4Ah
		int 	21h
		jc 		MCATCH
		jmp 	MDEFAULT
	MCATCH:
		mov 	MEMORY_ERROR, 1
	MDEFAULT:
	ret
MEMORY_FREE 	ENDP

GET_PATH PROC
		push    AX
		push    DI
		push    SI
		push    ES
		
        mov     SI, 0h
		mov     OVL_OFFSET, AX
		mov     AX, PSP_OFFSET
		mov     ES, AX
		mov     ES, ES:[2Ch]
	FIND_ZERO:
		mov     AX, ES:[SI]
		inc     SI
		cmp     AX, 0h
		jne     FIND_ZERO
		add     SI, 3h
		mov     DI, 0h
	WRITE:
		mov     AL, ES:[SI]
		cmp     AL, 0
		je      WRITE
		cmp     AL, '\'
		jne     ADD_SYMB
		mov     OVL_POS, DI
	ADD_SYMB:
		mov     BYTE PTR [PATH + DI], AL
        inc     SI
		inc     DI
		jmp     WRITE
	WRITE_NAME:
		cld
		mov     DI, OVL_POS
		inc     DI
		add     DI, offset PATH
		mov     SI, OVL_OFFSET
		mov     AX, DS
		mov     ES, AX
	UPDATE_NAME:
		lodsb
		stosb
		cmp     AL, 0
		jne     UPDATE_NAME
		
		pop     ES
		pop     SI
		pop     DI
		pop     AX
		ret
GET_PATH ENDP

GET_SIZE PROC
		push    AX
		push    BX
		push    CX
		push    DX
		push    SI

		mov     AX, 1A00h
		mov     DX, offset DTA
		int     21h
		mov     AH, 4Eh
		mov     CX, 0
		mov     DX, offset PATH
		int     21h
		jnc     GS_SUCCESS
		mov     DX, offset SIZE_ERROR_MSG
		call    PRINT_STRING
		cmp     AX, 2
		je      NOFILE
		cmp     AX, 3
		je      NOPATH
		jmp     GET_END
	NOFILE:
		mov     DX, offset NOFILE_MSG
		call    PRINT_STRING
		jmp     GET_END
	NOPATH:
		mov     DX, offset NOPATH_MSG
		call    PRINT_STRING
		jmp     GET_END
	SUCCESS:
		mov     SI, offset DTA
		add     SI, 1Ah
		mov     BX, [SI]
		mov     AX, [SI + 2]
        push    CX
        mov     CL, 4
		shr     BX, CL
        mov     CL, 12
		shl     AX, CL
        pop     CX
		add     BX, AX
		add     BX, 2
		mov     AX, 4800h
		int     21h
		jnc     SET_SEG
		jmp     GET_END
	SET_SEG:
		mov     OVL_PARAM, AX
	GET_END:
		pop     SI
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
GET_SIZE ENDP

LOAD_OVL PROC
		push    AX
		push    BX
		push    DX
		push    ES
		
		mov     DX, offset PATH
		push    DS
		pop     ES
		mov     BX, offset OVL_PARAM
		mov     AX, 4B03h
		int     21h
		jnc     SUCCESS		
		mov     DX, offset ERROR_LOAD_MSG
		call    PRINT_STRING
	SUCCESS:
		mov     AX, OVL_PARAM
		mov     ES, AX
		mov     WORD PTR OVL_ADRESS + 2, AX
		call    OVL_ADRESS
		mov     ES, AX
		mov     AH, 49h
		int     21h
	LOAD_END:
		pop     ES
		pop     DX
		pop     BX
		pop     AX
	ret
LOAD_OVL ENDP

EXECUTE_OVL PROC
		call    GET_PATH
		call    GET_SIZE
		call    LOAD_OVL
	ret
EXECUTE_OVL ENDP

BEGIN:
		mov     AX, DATA
		mov     DS, AX
		mov     PSP_SEGMENT, ES
		call    MEMORY_FREE
		mov     AX, offset OVL1_NAME
		call    EXECUTE_OVL
		mov     AX, offset OVL2_NAME
		call    EXECUTE_OVL	
	TO_DOS:
		mov     AX, 4C00h
		int     21h
CODE ENDS

PROGEND:

END BEGIN

