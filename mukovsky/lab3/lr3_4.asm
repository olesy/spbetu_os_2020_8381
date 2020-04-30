LAB SEGMENT
	ASSUME CS:LAB, DS:LAB, ES:NOTHING, SS:NOTHING
	ORG 100H
MAIN: JMP BEGIN

;данные
AVAILABLE_MEMORY db 'Available memory: $' 
EXPENDED_MEMORY  db 'Expanded memory: $' 
MCB_NUM_INFO     db  'MCB number $'
AREA_SIZE_INFO 	 db  '   Area size: $'
END_LINE 		 db  0Dh, 0Ah, "$"
KBYTES 			 db ' kbytes', 13,10,'$'
BLOCK 			 db  0Dh, 0Ah, 'Block is $'
FREE 		     db 'free$'
XMS 		     db 'OS XMS UMB$'
DRIVER_TOP 	     db 'Excluded top memory of driver$'
DOS 			 db 'MSDOS$'
OCCUP_386 		 db '386MAX UMB$'
BLOCK_386 		 db '386MAX$'
BELONG_386 		 db '386MAX UMB$'




;--------------------------------------------------------------------------------
PRINT PROC NEAR
		PUSH AX
		MOV AH, 09H
		INT 21H
		POP AX
		RET
PRINT ENDP
;--------------------------------------------------------------------------------
PRINT_KBYTES PROC NEAR
		PUSH DX
		MOV DX, OFFSET KBYTES
		CALL PRINT
		POP DX
		RET
PRINT_KBYTES ENDP		
;--------------------------------------------------------------------------------
;ВЫВОДИТ СЛОВО(AX) В 10 С/С
DEC_WORD_PRINT PROC
		PUSH AX
		PUSH CX
		PUSH DX
		PUSH BX
		MOV BX, 10
		XOR CX, CX
	;В ЦИКЛЕ ДЕЛИМ ЧИСЛО(AX) НА 10(BX) И ОСТАТКИ ОТ ДЕЛЕНИЯ(DX) ЗАНОСИМ В СТЕК 
	GET_NUMBERS:
		DIV BX  
		PUSH DX
		XOR DX, DX
		INC CX
		CMP AX, 0
		JNZ GET_NUMBERS
		
	;В ЦИКЛЕ ДОСТАЕМ ИЗ СТЕКА ЧИСЛА В 10 С/С И ВЫВОДИМ
	WRITING:
		POP DX
		OR DL, 48 ;СДВИГ В ASCII ДО ЦИФР
		MOV AH, 2
		INT 21H
		LOOP WRITING
	
		POP BX
		POP DX
		POP CX
		POP AX
		RET
DEC_WORD_PRINT ENDP
;--------------------------------------------------------------------------------
;ВЫВОДИТ БАЙТ(AL) В 16 С/С
HEX_BYTE_PRINT PROC NEAR
		PUSH AX
		PUSH BX
		PUSH DX
		
		MOV AH, 0
		MOV BL, 10H
		DIV BL 
		MOV DX, AX ;В DL - ПЕРВАЯ ЦИФРА В DH - ВТОРАЯ
		MOV AH, 02H
		CMP DL, 0AH 
		JL PRINT_1	;ЕСЛИ В DL - ЦИФРА
		ADD DL, 7   ;СДВИГ В ASCII С ЦИФР ДО БУКВ
	PRINT_1:
		ADD DL, 48
		INT 21H
		MOV DL, DH
		CMP DL, 0AH
		JL PRINT_2   
		ADD DL, 7	
	PRINT_2:
		ADD DL, 48
		INT 21H;
		POP DX
		POP BX
		POP AX
		RET
	HEX_BYTE_PRINT ENDP
;--------------------------------------------------------------------------------
;ВЫВОДИТ СЛОВО(AX) В 16 С/С
HEX_WORD_PRINT PROC NEAR
		PUSH AX
		PUSH DX
		MOV DX,AX
		MOV AL,DH
		CALL HEX_BYTE_PRINT
		MOV AL,DL
		CALL HEX_BYTE_PRINT
		POP DX
		POP AX
		RET
HEX_WORD_PRINT ENDP
;--------------------------------------------------------------------------------

FREE_MEMORY 	PROC
		PUSH 	AX
		PUSH 	BX
		PUSH 	CX
		
		MOV 	BX, OFFSET PROGRAM_END
		ADD 	BX, 100H
		MOV 	CL, 4
		SHR 	BX, CL
		ADD 	BX, 17
		MOV 	AH, 4AH
		INT 	21H

		POP 	CX
		POP 	BX
		POP 	AX
	RET
FREE_MEMORY	 ENDP
;--------------------------------------------------------------------------------
ADD_MEMORY     PROC
		PUSH 	AX
		PUSH 	BX
	
		MOV 	BX, 1000H
		MOV 	AH, 48H
		INT 	21H

		POP 	BX
		POP 	AX
	RET
ADD_MEMORY      ENDP
;--------------------------------------------------------------------------------

BEGIN:
		PUSH 	AX
		PUSH 	BX
		PUSH 	CX
		PUSH 	DX
		PUSH 	ES
		PUSH 	SI
		
		call ADD_MEMORY
		call FREE_MEMORY
		
	PRINT_AVAILABLE_MEMORY:
		XOR     AX, AX
		INT 	12H
		
		MOV     DX, OFFSET AVAILABLE_MEMORY
		CALL    PRINT
		XOR		DX, DX
		CALL    DEC_WORD_PRINT
		CALL    PRINT_KBYTES
		
	PRINT_EXPENDED_MEMORY:
		MOV 	AL, 30H
		OUT 	70H, AL
		IN 		AL, 71H 
		MOV 	BL, AL 
		MOV 	AL, 31H  
		OUT 	70H, AL
		IN 		AL, 71H

		MOV 	AH, AL
		MOV 	AL, BL

        MOV 	DX, OFFSET EXPENDED_MEMORY
		CALL 	PRINT
		XOR		DX, DX
		CALL 	DEC_WORD_PRINT
        CALL    PRINT_KBYTES
		
	
	PRINT_MCB:
		MOV 	AH, 52H
		INT 	21H
		MOV 	AX, ES:[BX-2] ;АДРЕСС ПЕРВОГО MCB
		MOV 	ES, AX
		XOR 	CX, CX
		
	NEXT_MCB:
		INC 	CX
		MOV 	DX, OFFSET MCB_NUM_INFO
		PUSH 	CX
		CALL 	PRINT
		MOV 	AX, CX
		XOR 	DX, DX
		CALL	DEC_WORD_PRINT ;ВЫВОДИТ НОМЕР ТЕКУЩЕГО MCB
	START:
		MOV 	DX, OFFSET BLOCK
		CALL 	PRINT
		XOR 	AX, AX
		MOV 	AL, ES:[0H]
		PUSH 	AX
		MOV 	AX, ES:[1H]
		
		CMP 	AX, 0H
		JE 		FREE_PRINT
		CMP 	AX, 6H
		JE 		XMS_PRINT
		CMP 	AX, 7H
		JE 		DRIVER_TOP_PRINT
		CMP 	AX, 8H
		JE 		DOS_PRINT
		CMP 	AX, 0FFFAH
		JE 		OCCUP_386_PRINT
		CMP 	AX, 0FFFDH
		JE 		BLOCK_386_PRINT
		CMP 	AX, 0FFFEH
		JE 		BELONG_386_PRINT
		
		XOR 	DX, DX
		CALL 	HEX_WORD_PRINT
		JMP 	AREA_SIZE_START
		
	FREE_PRINT:
		MOV 	DX, OFFSET FREE
		JMP 	PRINTING   
	XMS_PRINT:
		MOV 	DX, OFFSET XMS
		JMP 	PRINTING
	DRIVER_TOP_PRINT:
		MOV 	DX, OFFSET DRIVER_TOP
		JMP 	PRINTING
	DOS_PRINT:
		MOV 	DX, OFFSET DOS
		JMP 	PRINTING
	OCCUP_386_PRINT:
		MOV 	DX, OFFSET OCCUP_386
		JMP 	PRINTING
	BLOCK_386_PRINT:
		MOV 	DX, OFFSET BLOCK_386
		JMP 	PRINTING
	BELONG_386_PRINT:
		MOV 	DX, OFFSET BELONG_386
	PRINTING:
		CALL 	PRINT
	
	AREA_SIZE_START:	
		MOV 	DX, OFFSET AREA_SIZE_INFO
		CALL 	PRINT
		MOV 	AX, ES:[3H]
		MOV 	BX, 10H
		MUL 	BX
		CALL 	DEC_WORD_PRINT

		MOV 	CX, 8
		XOR 	SI, SI
		MOV 	DX, OFFSET END_LINE
		CALL 	PRINT

	LAST_BYTES_START:
		MOV     DL, ES:[SI + 8H]
		MOV     AH, 02H
		INT     21H
		INC     SI
		LOOP    LAST_BYTES_START
		
		MOV     AX, ES:[3H]
		MOV     BX, ES
		ADD     BX, AX
		INC     BX
		MOV     ES, BX
		POP     AX
		POP     CX
		CMP     AL, 5AH
		JE      EXIT
		MOV     DX, OFFSET END_LINE
		CALL    PRINT
		JMP     NEXT_MCB
		
	EXIT:		
		POP		SI
		POP 	ES
		POP		DX
		POP 	CX
		POP		BX
		POP		AX
		XOR		AL, AL
		MOV 	AH, 4CH
		INT		21H
		RET

	PROGRAM_END:

LAB 	ENDS
		END  	MAIN
