TESTPC SEGMENT 
	ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING 
	org 100h

START:  JMP BEGIN	

; DATA SEGMENT

INACCESSIBLE_MEMORY db 			"Inaccessible  memery address:          ", 0dh, 0ah, '$'
ENVIRONMENT_SEGMENT_ADDRESS db 	"Environment segment address:    		", 0dh, 0ah, '$'
ENVIRONMENT_DATA db 			"Environment data: 						", 0dh, 0ah, '$'

END_OF_LINE db " ", 0dh, 0ah, '$'

START_PATH db "Start directory: ", 0dh, 0ah, '$'

COMMAND_TEXT db "Command line tail: "
COMMAND_TAIL db "                                               		", 0dh, 0ah, '$'

; CODE SEGMENT

;--------------------------------------------------------------------------------
PRINT_STRING PROC near
		push AX
		mov AH, 09h
		int	21h
		pop AX
		ret
PRINT_STRING ENDP
;--------------------------------------------------------------------------------

TETR_TO_HEX PROC near

	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	add AL, 30h
	ret
TETR_TO_HEX ENDP

; байт AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX 
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ; в AL - старшая, в AH - младшая
	pop CX
	ret
BYTE_TO_HEX ENDP

; перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

;--------------------------------------------------------------------------------

FUNCTION_NOT_AVAILABLE_MEMORY PROC NEAR
	push AX
	push DI
	
	mov AX, DS:[02h] 
	mov DI, offset INACCESSIBLE_MEMORY
	add DI, 020h
	call WRD_TO_HEX

	mov DX, offset INACCESSIBLE_MEMORY
	call PRINT_STRING
	
	pop DI
	pop AX
	ret
FUNCTION_NOT_AVAILABLE_MEMORY ENDP

;--------------------------------------------------------------------------------

FUNCTION_ENVIRONMENT_SEGMENT_ADDRESS PROC NEAR
	push AX
	push DI
	
	mov AX, DS:[02Ch] 
	mov DI, offset ENVIRONMENT_SEGMENT_ADDRESS
	add DI, 01Fh
	call WRD_TO_HEX

	mov DX, offset ENVIRONMENT_SEGMENT_ADDRESS
	call PRINT_STRING
	
	pop DI
	pop AX
	ret
FUNCTION_ENVIRONMENT_SEGMENT_ADDRESS ENDP

;--------------------------------------------------------------------------------

FUNCTION_COMMAND_TAIL PROC NEAR
	push AX
	push BX
	push CX
	push DX

	push SI
	push DI

	mov SI, 80h
	xor CX, CX
	mov CL, byte ptr cs:[SI]
	mov BX, offset COMMAND_TAIL

	inc SI
	cycle_begin:
		cmp CL, 0h
		jz cycle_end

		xor AX, AX
		mov AL, byte ptr cs:[SI]
		mov [BX], AL

		add BX, 1
		sub CL, 1
		add SI, 1

		jmp cycle_begin
	cycle_end:

	xor AX, AX
	mov AL, 0Ah
	mov [BX], AL
	inc BX
	mov AL, '$'
	mov [BX], AL

	mov DX, offset COMMAND_TEXT
	call PRINT_STRING
	mov DX, offset END_OF_LINE
	call PRINT_STRING
	
	pop DI
	pop SI
	
	pop DX
	pop CX
	pop BX
	pop AX

	ret
FUNCTION_COMMAND_TAIL ENDP

;--------------------------------------------------------------------------------

FUNCTION_ENVIRONMENT_DATA PROC NEAR
	push AX
	push DX
	push DS	
	push ES

	mov DX, offset ENVIRONMENT_DATA
	call PRINT_STRING
	
 	mov AH, 02h
	mov ES, DS:[02Ch]
	xor SI,SI

	cycle1_begin:
		mov DL, ES:[SI]
		int 21h
		cmp DL, 0h
		je cycle1_end
		inc SI
		jmp cycle1_begin
	cycle1_end:

	mov DX, offset END_OF_LINE
	call  PRINT_STRING

	inc SI
	mov DL, ES:[SI]
	cmp DL, 0h
	jne cycle1_begin
 	
	mov DX, offset END_OF_LINE
	call PRINT_STRING
	
	mov DX, offset START_PATH
	call PRINT_STRING
	
	add SI, 3h
	mov AH, 02h
	mov ES, DS:[02Ch]

	cycle2_begin:
		mov DL, ES:[SI]
		cmp DL, 0h
		je cycle2_end
		int 21h
		inc SI
		jmp cycle2_begin
	cycle2_end:
 	
	pop ES
	pop DS
	pop DX
	pop AX
	ret
FUNCTION_ENVIRONMENT_DATA ENDP

;--------------------------------------------------------------------------------

begin:

	call FUNCTION_NOT_AVAILABLE_MEMORY
	call FUNCTION_ENVIRONMENT_SEGMENT_ADDRESS
	call FUNCTION_COMMAND_TAIL
	call FUNCTION_ENVIRONMENT_DATA

	xor AL, AL
	mov AH, 4Ch
	int 21h

TESTPC 	ENDS
		END START

; find me https://github.com/Nik-Poch
