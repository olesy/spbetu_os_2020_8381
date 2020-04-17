ASTACK 	SEGMENT  STACK 
	DW 100h DUP(?)    
ASTACK 	ENDS 
 
DATA SEGMENT

pc db 'PC', 0dh, 0ah, '$'
pc_xt db 'PC/XT', 0dh, 0ah, '$'
at_ db	'AT', 0dh, 0ah, '$'
ps2_30 db 'PS2 model 30', 0dh, 0ah, '$'
ps2_5060 db 'PS2 model 50/60', 0dh, 0ah, '$'
ps2_80 db 'PS2 model 80', 0dh, 0ah, '$'
pcjr db 'PCjr', 0dh, 0ah, '$'
pc_convertible db 'PC Convertible', 0dh, 0ah, '$'

pc_type db	'Тип PC: ','$'
msdos_version db 'Версия MS DOS:  . ', 0dh, 0ah, '$'
oem_number	db 'Номер ОЕМ:     ', 0dh, 0ah, '$'
serial_number db	'Серийный номер:     ', 0dh, 0ah, '$'

DATA ENDS

CODE SEGMENT
	ASSUME cs:CODE, ds: DATA, ss: ASTACK
	
;Процедуры
	
;Перевод между с.сч.

tetr_to_hex	proc near
	and	al, 0fh
	cmp al, 09
	jbe	next
	add	al, 07
	next: add al, 30h
	ret
tetr_to_hex	endp

byte_to_hex	proc near
	push cx
	mov	al, ah
	call tetr_to_hex
	xchg al, ah
	mov	cl, 4
	shr	al, cl
	call tetr_to_hex 
	pop	cx 			
	ret
byte_to_hex	endp

word_to_hex	proc near
	push bx
	mov	bh, ah
	call byte_to_hex
	mov [di], ah
	dec	di
	mov [di], al
	dec	di
	mov	al, bh
	xor	ah, ah
	call byte_to_hex
	mov	[di], ah
	dec	di
	mov	[di], al
	pop	bx
	ret
word_to_hex	endp

byte_to_dec	proc near
	push cx
	push dx
	push ax
	xor	ah, ah
	xor	dx, dx
	mov	cx, 10
loop_bd: 
	div	cx
	or dl, 30h
	mov	[si], dl
	dec	si
	xor	dx, dx
	cmp	ax, 10
	jae	loop_bd
	cmp	ax, 00h
	jbe	end_l
	or al, 30h
	mov	[si], al
end_l:	
	pop	ax
	pop	dx
	pop	cx
	ret
byte_to_dec	endp

;Вывод строк
print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print endp

print_a_pc_type:
	call print
	jmp GET_OS

print_pc:
	mov dx, offset pc
	jmp print_a_pc_type
	
print_pc_xt:
	mov dx, offset pc_xt
	jmp print_a_pc_type
	
print_at:
	mov dx, offset at_
	jmp print_a_pc_type
	
print_ps2_30:
	mov dx, offset ps2_30
	jmp print_a_pc_type

print_ps2_5060:
	mov dx, offset ps2_5060
	jmp print_a_pc_type
	
print_ps2_80:
	mov dx, offset ps2_80
	jmp print_a_pc_type
	
print_pcjr:
	mov dx, offset pcjr
	jmp print_a_pc_type
	
print_pc_convertible:
	mov dx, offset pc_convertible
	jmp print_a_pc_type

;Основные процедуры
MAIN proc far
GET_PC:
	push dx
	push ax
	
	;Загрузка сегмента данных в регистр
	mov ax, data
	mov ds, ax
		
	mov dx, offset pc_type
	call print ; Вывод: "Тип PC: "
	
	mov ax, 0F000h ;указывает ES на ПЗУ
	mov es, ax
	mov al, es:[0FFFEh]
	
	;Получаем в al значение кода типа IBM PC
	mov ax, 0F000h 
	mov es, ax
	mov al, es:[0FFFEh]
	
	;FF => PC
	cmp al, 0FFh
	je print_pc
	
	;FE, FB => PC/XT
	cmp al, 0FEh
	je print_pc_xt
	cmp al, 0FBh
	je print_pc_xt
	
	;FC => AT
	cmp al, 0FCh
	je print_at
	
	;FA => ps2_30
	cmp al, 0FAh
	je print_ps2_30
	
	;FC => ps2_5060
	cmp al, 0FCh
	je print_ps2_5060
	
	;F8 => ps2_80
	cmp al, 0F8h
	je print_ps2_80
	
	;FD => PCjr
	cmp al, 0FDh
	je print_pcjr
	
	;F9 => PC convertible
	cmp al, 0F9h
	je print_pcjr


GET_OS:
;Выходные параметры:
;al - основная версия, ah - модификация, bh - OEM, bl:cx - 24 битовый серийный номер пользователя
	mov ah, 30h
	int 21h 
	
	lea si, msdos_version
	add si, 15	
	;записываем основную версиб
	call byte_to_dec 	
	add	si, 3
	;запись номера модификации в al
	mov al, ah
	;печать номер модификации
	call byte_to_dec
	mov dx, offset msdos_version
	call print

GET_OEM:
	mov al, bh
	lea si, oem_number
	add si, 11
	call byte_to_dec
	mov dx, offset oem_number
	call print

GET_SERIAL_NUMBER:
	mov	al, bl
	lea si, serial_number
	add si, 16
	call byte_to_hex
	mov [si], ax
	add	si, 6
	mov	di, si
	mov ax, cx
	call word_to_hex
	mov dx, offset serial_number
	call print


	pop di
	pop si
	pop dx
	pop	ax	
	mov ah, 4ch
	int	21h
	ret 

MAIN ENDP
CODE ENDS
END MAIN