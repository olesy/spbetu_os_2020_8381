ASTACK SEGMENT STACK
	DW 100h DUP(?)
ASTACK ENDS

;данные
DATA SEGMENT
	PC			DB	'PC', 0DH, 0AH,'$'
	PC_XT		DB	'PC/XT', 0DH, 0AH,'$'
	AT_			DB	'AT', 0DH, 0AH, '$'
	PS2_30	 	DB	'PS2 MODEL 30', 0DH, 0AH, '$'
	PS2_5060	DB	'PS2 MODEL 50/60', 0DH, 0AH, '$'
	PS2_80		DB	'PS2 MODEL 80', 0DH, 0AH, '$'
	PCJR 		DB	'Psjr', 0DH, 0AH, '$'
	PC_CONVERTIBLE	DB	'PC CONVERTIBLE', 0DH, 0AH, '$'
	TYPE_ANOTHER DB 'ANOTHER TYPE: ',0DH, 0AH, '$'
	IBM_PC_NAME		DB	'IBM PC TYPE: ', '$'
	OS_NAME			DB	'MSDOS VERSION:  . ', 0DH, 0AH, '$'
	OEM_NAME		DB	'OEM NUMBER:     ', 0DH, 0AH, '$'
	SERIAL_NAME		DB	'SERIAL NUMBER:      ', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK

TETR_TO_HEX	PROC NEAR
		AND	AL, 0FH
		CMP AL, 09
		JBE	NEXT
		ADD	AL, 07
		NEXT: ADD AL, 30H
		RET
TETR_TO_HEX	ENDP

;--------------------------------------------------------------------------------

BYTE_TO_HEX	PROC NEAR
;байт в al переводится в два символа шест. числа в ax
		PUSH CX
		MOV	AH, AL
		CALL TETR_TO_HEX
		XCHG AL, AH
		MOV	CL, 4
		SHR	AL, CL
		CALL TETR_TO_HEX ;в al старшая цифра
		POP	CX 			 ;в ah младшая цифра
		RET
BYTE_TO_HEX	ENDP

;--------------------------------------------------------------------------------

WRD_TO_HEX	PROC NEAR
;перевод в 16 с/с 16 разрядного числа
;в ax - число, di - адрес последнего символа
		PUSH BX
		MOV	BH, AH
		CALL BYTE_TO_HEX
		MOV [DI], AH
		DEC	DI
		MOV [DI], AL
		DEC	DI
		MOV	AL, BH
		XOR	AH, AH
		CALL BYTE_TO_HEX
		MOV	[DI], AH
		DEC	DI
		MOV	[DI], AL
		POP	BX
		RET
WRD_TO_HEX	ENDP

;--------------------------------------------------------------------------------

BYTE_TO_DEC	PROC NEAR
;перевод в 10 с/с, si - адрес поля младшей цифры
		PUSH CX
		PUSH DX
		PUSH AX
		XOR	AH, AH
		XOR	DX, DX
		MOV	CX, 10
LOOP_BD: 
		DIV	CX
		OR DL, 30H
		MOV	[SI], DL
		DEC	SI
		XOR	DX, DX
		CMP	AX, 10
		JAE	LOOP_BD
		CMP	AX, 00H
		JBE	END_L
		OR AL, 30H
		MOV	[SI], AL
END_L:	
		POP	AX
		POP	DX
		POP	CX
		RET
BYTE_TO_DEC	ENDP

;--------------------------------------------------------------------------------

PRINT PROC NEAR
		PUSH AX
		MOV AH, 09H
		INT 21H
		POP AX
		RET
PRINT ENDP

;--------------------------------------------------------------------------------

	

MAIN PROC FAR
	JMP BEGIN
	PC_WRITE:
		MOV DX, OFFSET PC
		JMP WRITE

	PC_XT_WRITE:
		MOV DX, OFFSET PC_XT
		JMP WRITE

	AT_WRITE:
		MOV DX, OFFSET AT_
		JMP WRITE

	PS2_30_WRITE:
		MOV DX, OFFSET PS2_30
		JMP WRITE

	PS2_5060_WRITE:
		MOV DX, OFFSET PS2_5060
		JMP WRITE

	PS2_80_WRITE:
		MOV DX, OFFSET PS2_80
		JMP WRITE

	PCJR_WRITE:
		MOV DX, OFFSET PCJR
		JMP WRITE

	PC_CONVERTIBLE_WRITE:
		MOV DX, OFFSET PC_CONVERTIBLE
		JMP WRITE

	PC_ANOTHER_WRITE:
		MOV DX, OFFSET TYPE_ANOTHER
		JMP WRITE
		
	WRITE:
		CALL PRINT
		JMP OS
		
	
	BEGIN:
		PUSH DX
		PUSH AX
		
		MOV AX, DATA
		MOV DS, AX
	
		MOV DX, OFFSET IBM_PC_NAME
		CALL PRINT

		MOV AX, 0F000H 
		MOV ES, AX
		MOV AL, ES:[0FFFEH]
		
		CMP AL, 0FFH	
		JE 	PC_WRITE
		CMP AL, 0FEH
		JE PC_XT_WRITE
		CMP AL, 0FBH
		JE PC_XT_WRITE
		CMP AL, 0FCH
		JE AT_WRITE
		CMP AL, 0FAH
		JE PS2_30_WRITE
		CMP AL, 0FCH
		JE PS2_5060_WRITE
		CMP AL, 0F8H
		JE PS2_80_WRITE
		CMP AL, 0FDH
		JE PCJR_WRITE
		CMP AL, 0F9H
		JE PC_CONVERTIBLE_WRITE
	
		JMP PC_ANOTHER_WRITE

	OS:
		MOV AH, 30H ;дает номер версии dos  al - основная версия, ah - номер модификации
		INT 21H
		LEA		SI, OS_NAME
		ADD		SI, 15 
		CALL	BYTE_TO_DEC
		ADD		SI, 3
		MOV 	AL, AH
		CALL   	BYTE_TO_DEC
		MOV DX, OFFSET OS_NAME
		CALL PRINT

	OEM:
		MOV 	AL, BH ;bh - серийный номер
		LEA 	SI, OEM_NAME
		ADD 	SI, 12
		CALL 	BYTE_TO_DEC
		MOV 	DX, OFFSET OEM_NAME
		CALL 	PRINT
		
	SERIAL:
		MOV		AL, BL 
		LEA		SI, SERIAL_NAME
		ADD		SI, 15
		CALL	BYTE_TO_HEX
		MOV		[SI], AX
		ADD		SI, 6
		MOV		DI, SI
		
		MOV 	AX, CX
		CALL	WRD_TO_HEX
		MOV 	DX, OFFSET SERIAL_NAME
		CALL 	PRINT
		
		POP		AX
		POP 	DX
		XOR		AL, AL
		MOV 	AH, 4CH
		INT		21H
		RET

MAIN 	ENDP
CODE ENDS
		END  	MAIN