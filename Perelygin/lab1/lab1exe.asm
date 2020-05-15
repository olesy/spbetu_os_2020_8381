
AStack    SEGMENT  STACK
          DW 100 DUP(1)    
AStack    ENDS


DATA      SEGMENT


TYPEPC db 'Your PC type: $'
PC db 'PC', 13,10,'$'
PCXT db 'PC/XT', 13,10,'$'
PCAT db 'AT$', 13,10,'$'
PS2MODEL30 db 'PS2 (30 model)', 13,10,'$'
PS2MODEL50OR60 db 'PS2 (50 or 60 model)', 13,10,'$'
PS2MODEL80 db 'PS2 (80 model)', 13,10,'$'
PCJR db 'PC jr', 13,10,'$'
PCCONVERTIBLE db 'PC Convertible', 13,10,'$'

DOT db '.$'
VERSION db 13, 10, 'Your version number: $'
OEM db 13, 10, 'Your OEM: $'
USER db 13, 10, 'Your User ID: $'



DATA      ENDS


CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack


PRINT	  PROC  NEAR
          mov   AH,9
          int   21h 
          ret
PRINT     ENDP



OutInt proc near
        
;;Число для вывода должно находиться в AX.
;; Количество цифр будем держать в CX.
;; dx основание сс
    xor     cx, cx
    mov     bx, dx ; основание сс. 10 для десятеричной и т.п.
oi2:
    xor     dx,dx
    div     bx
; Делим число на основание сс. В остатке получается последняя цифра.
; Сразу выводить её нельзя, поэтому сохраним её в стэке.
    push    dx
    inc     cx
; А с частным повторяем то же самое, отделяя от него очередную
; цифру справа, пока не останется ноль, что значит, что дальше
; слева только нули.
    test    ax, ax
    jnz     oi2
; Теперь приступим к выводу.
    mov     ah, 02h
oi3:
    pop     dx
; Извлекаем очередную цифру, переводим её в символ и выводим.


    cmp     dl,9
    jbe     oi4
    add     dl,7

oi4:
    add     dl, '0'
    int     21h
; Повторим ровно столько раз, сколько цифр насчитали.
    loop    oi3
    
    ret
 
OutInt endp






; Головная процедура
Main      PROC  FAR
		
		
		 push  DS       ;\  Сохранение адреса начала PSP в стеке
         sub   AX,AX    ; > для последующего восстановления по
         push  AX       ;/  команде ret, завершающей процедуру.
         mov   AX,DATA             ; Загрузка сегментного
         mov   DS,AX               ; регистра данных.
		
		
		;определение версии пк
		mov		DX, OFFSET TYPEPC
		call 	PRINT

		mov 	AX, 0F000h
		mov		ES, AX
		mov 	AX, 0
		mov 	AL, ES:[0FFFEh]

		
		cmp 	AL, 0FFh
		jz 		PCLABEL
		
		cmp 	AL, 0FEh
		jz 		PCXTLABEL
		
		cmp 	AL, 0FBh
		jz 		PCXTLABEL
		
		cmp 	AL, 0FCh
		jz 		PCATLABEL
		
		cmp 	AL, 0FAh
		jz 		PS2MODEL30LABEL
		
		cmp 	AL, 0FCh
		jz 		PS2MODEL50OR60LABEL
		
		cmp 	AL, 0F8h
		jz 		PS2MODEL80LABEL
		
		cmp 	AL, 0FDh
		jz 		PCJRLABEL
		
		cmp 	AL, 0F9h
		jz 		PCCONVERTIBLELABEL
		
		jmp 	UNKNOWN_TYPE_LABEL ;ни один из известных типов не подошел
		
PCLABEL:
		mov 	DX, OFFSET PC
		jmp 	PCTYPE_OUT
PCXTLABEL:		
		mov 	DX, OFFSET PCXT
	    jmp 	PCTYPE_OUT
PCATLABEL:
		mov 	DX, OFFSET PCAT
		jmp 	PCTYPE_OUT
PS2MODEL30LABEL:
		mov 	DX, OFFSET PS2MODEL30
		jmp 	PCTYPE_OUT
PS2MODEL50OR60LABEL:
		mov 	DX, OFFSET PS2MODEL50OR60
		jmp 	PCTYPE_OUT
PS2MODEL80LABEL:
		mov 	DX, OFFSET PS2MODEL80
		jmp 	PCTYPE_OUT
PCJRLABEL:
		mov 	DX, OFFSET PCJR
		jmp 	PCTYPE_OUT
PCCONVERTIBLELABEL:
		mov 	DX, OFFSET PCCONVERTIBLE
		jmp 	PCTYPE_OUT
UNKNOWN_TYPE_LABEL:
		mov		DX, 16
		call 	OutInt
		jmp		MSDOS_VERSION ;номер выведем сами, пропускаем общий принт
		

PCTYPE_OUT:
		call 	PRINT ;в dx уже есть нужное смещение, вывод типа компьютера
		
MSDOS_VERSION:	

		;получаем необходимые данные, сохраняем в стек
		mov 	AH,30h       
		int 	21h 

		push 	cx
		push 	bx
		push 	ax
		
		;al main version
		;ah mod number
		;bh oem
		;bl:cx id
		
		mov		DX, OFFSET VERSION
		call 	PRINT
		
		;печать содержимого al
		mov 	ax, 0
		pop 	ax 	
		push 	ax ;значение ah еще понадобится, сохраняем в стек 
		
		mov 	ah, 0
		mov 	dx, 10
		call 	OutInt
		
		mov		DX, OFFSET DOT
		call 	PRINT
		
		;печать содержимого ah
		pop 	ax
		mov 	ah, ch
		mov 	ah, 0
		mov 	al, ch

		mov 	dx, 10
		call 	OutInt
		
		;oem
		mov		DX, OFFSET OEM
		call 	PRINT
		
		pop 	ax
		push 	ax
		mov 	ah, ch
		mov 	ah, 0
		mov 	al, ch
		
		mov 	dx, 10
		call 	OutInt
		
		;user id
		mov		DX, OFFSET USER
		call 	PRINT
		
		pop 	ax
		mov 	ah, 0
		cmp 	al, 0
		jz 		NEXT_NUMBER ;для того чтобы не печатать два ноля сразу переходим к печати cx
		
		mov 	dx, 10
		call 	OutInt
		
NEXT_NUMBER:
	
		pop 	ax
		mov 	dx, 10
		call 	OutInt

		;end
		;xor 	AL, AL
		;mov 	AH, 4CH
		;int 	21H
		
		ret ;;сам выйдет в дос
		
Main      ENDP
CODE      ENDS
          END Main