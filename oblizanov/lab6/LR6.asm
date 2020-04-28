.model small
.data

STR_SUCCESS		db	13, 10, "Program ended with code $"
STR_NOFILENAME		db  "File was not founded", 13, 10, "$"
STR_CTRLC		db	"Program ended by CRTL+C command", 13, 10, "$"

PSP 			dw 	?
SS_BACK 		dw 	?
SP_BACK 		dw 	?
FILENAME 			db 	50 dup(0)
ENDOFLINE 		db 	"$"
PARAM 			dw 	7 dup(?)
MEMORY_ERROR 	db 	0

.stack 100h

.code

TETR_TO_HEX		PROC	near
		and		al, 0fh
		cmp		al, 09
		jbe		NEXT
		add		al, 07
NEXT:	add		al, 30h
	ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC 	near
		push	cx
		mov		al, ah
		call	TETR_TO_HEX
		xchg	al, ah
		mov		cl, 4
		shr		al, cl
		call	TETR_TO_HEX 
		pop		cx 			
	ret
BYTE_TO_HEX		ENDP

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

EXIT_PROGRAM 	PROC
		mov 	AH, 4Dh
		int 	21h
		cmp 	AH, 1
		je 		ECTRLC
		lea 	DX, STR_SUCCESS
		call 	PRINT_STRING
		add		AH, '0'
		mov 	DL, AH
		mov 	AH, 2h
		int 	21h
		jmp 	EDEFAULT
	ECTRLC:
		lea 	DX, STR_CTRLC
		call 	PRINT_STRING
	EDEFAULT:
	ret
EXIT_PROGRAM 	ENDP

Main proc
		mov 	AX, @data
		mov 	DS, AX
		push 	SI
		push 	DI
		push 	ES
		push 	DX
		mov 	ES, ES:[2Ch]
		xor 	SI, SI
		lea 	DI, FILENAME
	ECHAR: 
		cmp 	byte ptr ES:[SI], 00h
		je 		ECHAREND
		inc 	SI
		jmp 	ENEXT
	ECHAREND:   
		inc 	SI
	ENEXT:       
		cmp 	word ptr ES:[SI], 0000h
		jne 	ECHAR
		add 	SI, 4
	NCHAR:
		cmp 	byte ptr ES:[SI], 00h
		je 		START
		mov 	DL, ES:[SI]
		mov 	[DI], DL
		inc 	SI
		inc 	DI
		jmp 	NCHAR
	START:
		sub 	DI, 5
		mov 	DL, '2'
		mov 	[DI], DL
		add 	DI, 2
		mov 	DL, 'c'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 'o'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 'm'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 0h
		mov 	[DI], DL
		inc 	DI
		mov 	DL, ENDOFLINE
		mov 	[DI], DL
		pop 	DX
		pop 	ES
		pop 	DI
		pop 	SI
		call 	MEMORY_FREE
		cmp 	MEMORY_ERROR, 0
		jne 	PDEFAULT
		push 	DS
		pop 	ES
		lea 	DX, FILENAME
		lea 	BX, param
		mov 	SS_BACK, SS
		mov 	SP_BACK, SP
		mov 	AX, 4B00h
		int 	21h
		mov 	SS, SS_BACK
		mov 	SP, SP_BACK
		jc 		NOFILENAME
		jmp 	MENDING
	NOFILENAME:
		lea 	DX, STR_NOFILENAME
		call 	PRINT_STRING
		lea 	DX, FILENAME
		call 	PRINT_STRING
		jmp 	PDEFAULT
	MENDING:
		call 	EXIT_PROGRAM
	PDEFAULT:
		mov 	AH, 4Ch
		int 	21h
main ENDP

PROGEND:

end main