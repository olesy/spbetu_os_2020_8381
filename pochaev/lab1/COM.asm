TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H	; резервирование места для PSP
START: 	JMP	BEGIN

; DATA SEGMENT
PC_TYPE			db	'PC', 0DH, 0AH,'$'
PC_XT_TYPE		db	'PC/XT', 0dh, 0ah,'$'
AT_TYPE			db	'AT', 0dh, 0ah, '$'
PS2_30_TYPE	 	db	'PS2 model 30', 0dh, 0ah, '$'
PS2_5060_TYPE	db	'PS2 model 50/60', 0dh, 0ah, '$'
PS2_80_TYPE		db	'PS2 model 80', 0dh, 0ah, '$'
PCjr_TYPE 		db	'PSjr', 0dh, 0ah, '$'
PC_CONVERTIBLE	db	'PC convertible', 0dh, 0ah, '$'

IBM_PC_NAME		db	'IBM PC type is: ', '$'
OS_NAME			db	'MSDOS version is:  . ', 0dh, 0ah, '$'
OEM_NAME		db	'OEM number is:     ', 0dh, 0ah, '$'
SERIAL_NAME		db	'Serial number is:      ', 0dh, 0ah, '$'
; DATA ENDS

; CODE SEGMENT


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
		push	bx
		mov		bh, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		dec		di
		mov		al, bh
		xor		ah, ah
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
;PC INFO OUT
		push DX
		push AX

		mov DX, offset IBM_PC_NAME
		call PRINT_STRING

		mov AX, 0F000H
		mov ES, AX
		mov AL, ES:[0FFFEH]
		cmp AL, 0FFh
		je PC_WRITE
		cmp AL, 0FEh
		je PC_XT_WRITE
		cmp AL, 0FBh
		je PC_XT_WRITE
		cmp AL, 0FCh
		je AT_WRITE
		cmp AL, 0FAh
		je PS2_30_WRITE
		cmp AL, 0FCh
		je PS2_5060_WRITE
		cmp AL, 0F8h
		je PS2_80_WRITE
		cmp AL, 0FDh
		je PCjr_WRITE
		cmp AL, 0F9H
		je PC_CONVERTIBLE_WRITE

PC_WRITE:
		mov DX, offset PC_TYPE
		jmp TYPE_WRITE

PC_XT_WRITE:
		mov DX, offset PC_XT_TYPE
		jmp TYPE_WRITE

AT_WRITE:
		mov DX, offset AT_TYPE
		jmp TYPE_WRITE

PS2_30_WRITE:
		mov DX, offset PS2_30_TYPE
		jmp TYPE_WRITE

PS2_5060_WRITE:
		mov DX, offset PS2_5060_TYPE
		jmp TYPE_WRITE

PS2_80_WRITE:
		mov DX, offset PS2_80_TYPE
		jmp TYPE_WRITE

PCjr_WRITE:
		mov DX, offset PCjr_TYPE
		jmp TYPE_WRITE

PC_CONVERTIBLE_WRITE:
		mov DX, offset PC_CONVERTIBLE
		jmp TYPE_WRITE

TYPE_WRITE:
		call PRINT_STRING

OS_INFO_GET:
		mov AH, 30h
		int 21h

OS_VERSION_SET:		
		lea		SI, OS_NAME
		add		SI, 18
		call	BYTE_TO_DEC
		add		SI, 3
		mov 	AL, AH
		call   	BYTE_TO_DEC

OS_VERSION_WRITE:
		mov DX, offset OS_NAME
		call PRINT_STRING

OEM_SET:
		mov 	AL, BH
		lea 	SI, OEM_NAME
		add 	SI, 15
		call 	BYTE_TO_DEC

OEM_WRITE:
		mov 	DX, offset OEM_NAME
		call 	PRINT_STRING

SERIAL_SET:
		mov		AL, BL
		lea		SI, SERIAL_NAME
		add		SI, 18
		call	BYTE_TO_HEX
		mov		[SI], AX
		add		SI, 6
		mov		DI, SI
		mov 	AX, CX
		call	WRD_TO_HEX

SERIAL_WRITE:
		mov 	DX, offset SERIAL_NAME
		call 	PRINT_STRING

ENDING:
		pop		AX
		pop 	DX

		xor		AL, AL
		mov 	AH, 4ch
		int		21h
		ret
TESTPC 	ENDS
		END  	START