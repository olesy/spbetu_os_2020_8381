AO SEGMENT ; Hello, I am Alexandr O.
	ASSUME  CS:AO, DS:AO, ES:NOTHING, SS:NOTHING
	ORG 100H

START: JMP BEGIN

INACCESSIBLE_MEMORY_INFO	db	"Inaccessible memory adress:       ", 13, 10, "$"
ENVIRONMENT_INFO			db	"Program environment adress:       ", 13, 10, "$"
LINE_TAIL_INFO				db	"Command line tail:                       ", 13, 10, "$"
ENVIRONMENT_CONTENT_INFO	db  "Program environment content:", 13, 10, "$"
ENVIRONMENT_CONTENT_END		db  "Program environment content ended", 13, 10, "$"
PATH_INFO					db  "Path:", 13, 10, "$"
NO_TAIL_INFO				db 	"No command line tail", 13, 10, "$"
TAIL_INFO					db  " $"
CONTENT_NEW_LINE			db	13, 10, "$"

; There is some basic procedures...

PRINT_STRING 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
		ret
PRINT_STRING 	ENDP
;--------------------------------------------------------------------------------
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
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near
		push 	bx
		push	ax
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		dec		di
		pop		ax
		mov		ah, al
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_DEC		PROC	near
		push	cx
		push	dx
		push	ax
		xor		ah, ah
		xor		dx, dx
		mov		cx, 10
loop_bd:div		cx
		or 		dl, 30h
		mov 	[si], dl
		dec 	si
		xor		dx, dx
		cmp		ax, 10
		jae		loop_bd
		cmp		ax, 00h
		jbe		end_l
		or		al, 30h
		mov		[si], al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP

BEGIN:
		push	AX
		push	DX

INACCESSIBLE_MEMORY_PRINT:
		mov 	DI, offset INACCESSIBLE_MEMORY_INFO
		add 	DI, 32
		mov 	AH, DS:[02h]
		mov		AL, DS:[03h]
		call	WRD_TO_HEX
		mov 	DX, offset INACCESSIBLE_MEMORY_INFO
		call	PRINT_STRING

ENVIRONMENT_PRINT:
		mov 	DI, offset ENVIRONMENT_INFO
		add 	DI, 32
		mov 	AH, DS:[2Ch]
		mov		AL, DS:[2Dh]
		call	WRD_TO_HEX
		mov 	DX, offset ENVIRONMENT_INFO
		call	PRINT_STRING

LINE_TAIL_PRINT:
		mov 	DX, offset LINE_TAIL_INFO
		call	PRINT_STRING
		mov 	AL, DS:[80h]
		cmp		AL, 0
		je		NO_TAIL
		mov 	DX, offset TAIL_INFO
		mov 	DI, offset TAIL_INFO
		mov		SI, 0
TAIL_CYCLE:
		mov		AL, DS:[81h + SI]
		mov 	AH, 02h
		int 	21h
		inc		SI
		cmp 	SI, AX
		jne		TAIL_CYCLE
NO_TAIL:
		mov 	DX, offset NO_TAIL_INFO
		call	PRINT_STRING

ENVIRONMENT_CONTENT_PRINT:
		mov		DX, offset ENVIRONMENT_CONTENT_INFO
		call	PRINT_STRING
		mov 	BX, 2Ch
		mov 	ES, [BX]
		xor 	SI, SI
		xor 	AX, AX
		mov		DX, offset CONTENT_NEW_LINE 
LINE_PRINT:
		mov 	AL, ES:[SI]
		cmp 	AL, 0
		jne		LINE_SYMB_PRINT
		mov 	DX, offset CONTENT_NEW_LINE
		call	PRINT_STRING
LINE_SYMB_PRINT:
		mov 	DL, AL
		xor 	AX, AX
		mov 	AH, 02h
		int 	21h
		inc 	SI
		mov 	AX, ES:[SI]
		cmp		AX, 0001h;
		je 		LINE_END	
		jmp 	LINE_PRINT
LINE_END:
		mov 	DX, offset ENVIRONMENT_CONTENT_END
		call	PRINT_STRING

PATH_PRINT:
		mov 	DX, offset PATH_INFO
		call 	PRINT_STRING
		add 	SI, 2
PATH_SYMB_PRINT:
		mov 	AL, ES:[SI]
		cmp		AL, 0
		je		ENDING
		mov		DL, AL
		mov		AH, 02h
		int		21h
		inc		SI
		jmp		PATH_SYMB_PRINT

ENDING:
		mov		DX, offset CONTENT_NEW_LINE
		call	PRINT_STRING
		pop 	DX
		pop		AX
		xor 	AL, AL

		mov 	AH, 01h
		int 	21h
		mov 	AH, 4Ch
		int 	21h
AO ENDS
END START


