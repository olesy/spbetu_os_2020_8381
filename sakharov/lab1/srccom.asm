LAB1 SEGMENT
      ASSUME CS:LAB1, DS:LAB1, ES:NOTHING, SS:NOTHING
      ORG 100H ; PSP

OFF_MSDOS EQU 18
OFF_OEM EQU 15
OFF_SERIAL EQU 18


START: JMP BEGIN


;DATA SEGMENT
    T_PC             db 'PC', 0dh, 0ah, '$'
    T_PC_XT          db 'PC/XT', 0dh, 0ah, '$'
    T_AT             db 'AT',0dh, 0ah, '$'
    T_PS2_30         db 'PS2 model 30', 0dh, 0ah, '$'
    T_PS2_5060       db 'PS2 model 50/60', 0dh, 0ah, '$'
    T_PS2_80         db 'PS2 model 80', 0dh, 0ah, '$'
    T_PCJR           db 'PCJR', 0dh, 0ah, '$'
    T_PC_CONVERTIBLE db 'PC convertible', 0dh, 0ah, '$'
    T_PC_UNKNOWN     db 'UNKNOWN:   ', 0dh, 0ah, '$'

    IBM_PC           db 'IBM PC type is: ', '$'
    MS_DOS_VERSION   db 'MSDOS version is: #.#', 0dh, 0ah, '$'
    OEM              db 'OEM number is: ##', 0dh, 0ah, '$'
    SERIAL           db 'Serial number is: ######', 0dh, 0ah, '$'
;DATA ENDS

;CODE SEGMENT
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT:
    add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX ; байт в AL переводится в два символа шестн. числа в AX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ; в AL старшая цифра
    pop CX ; в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ; 16 с/с 16 bit. В AX - число, DI – адрес последнего символа
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

BYTE_TO_DEC PROC near ; 10 с/с, SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd:
    div CX
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
end_l: pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

WriteMsg  PROC  NEAR
    mov   AH,9
    int   21h
    ret
WriteMsg  ENDP

TYPE_PC PROC near
    ; Save stack
    push AX
    push BX
    push CX
    push ES
    ; Show 'IBM PC' message
    mov DX, offset IBM_PC
    call WriteMsg
    ; Get PC type
    xor AH,AH
    mov CX, 0F000h
    mov ES,CX
    mov AL, ES:[0FFFEh]
    ; Check PC type name
    cmp AX, 0FFh
        jz PCM
    cmp AX, 0FEh
        jz PCXTM
    cmp AX, 0FBh
        jz PCXTM
    cmp AX, 0FCh
        jz ATM
    cmp AX, 0FAh
        jz PS230M
    cmp AX, 0F6h
        jz PS250M
    cmp AX, 0F8h
        jz PS280M
    cmp AX, 0FDh
        jz PCjr_TYPEM
    cmp AX, 0F9h
        jz PC_CONVERTM
    mov DX,offset T_PC_UNKNOWN
    jmp ENDPC

    PCM:
        mov DX,offset T_PC
        jmp ENDPC
    PCXTM:
        mov DX,offset T_PC_XT
        jmp ENDPC
    ATM:
        mov DX,offset T_AT
        jmp ENDPC
    PS230M:
        mov DX,offset T_PS2_30
        jmp ENDPC
    PS250M:
        mov DX,offset T_PS2_5060
        jmp ENDPC
    PS280M:
        mov DX,offset T_PS2_80
        jmp ENDPC
    PCjr_TYPEM:
        mov DX,offset T_PCJR
        jmp ENDPC
    PC_CONVERTM:
        mov DX,offset T_PC_CONVERTIBLE
        jmp ENDPC
    ENDPC:
        ; Write PC type
        call WriteMsg
        pop AX
        pop BX
        pop CX
        pop ES
        ret
TYPE_PC ENDP

MS_DOS_OEM_SERIAL PROC near
    ; Save stack
    push AX
    push BX
    push CX
    push DX
    ; Get system info
    xor AX, AX
    mov ah, 30h
    int 21h
    push BX ; BH = OEM
    push CX ; BL:CX = serial
    ; Get ms-dos version
    mov BX, offset MS_DOS_VERSION
    add BX, OFF_MSDOS
    ; Major number
    mov DH, AH
    xor AH, AH
    call BYTE_TO_HEX
    mov [BX], AH
    add BX, 2
    ; Minor number
    xor AX, AX
    mov AL, DH
    call BYTE_TO_HEX
    mov [BX],AX
    ; Print version
    mov DX, offset MS_DOS_VERSION
    call WriteMsg
    ; Get OEM
    pop CX
    pop BX
    xor DX, DX
    mov DX, BX
    mov BX, offset OEM
    add BX, OFF_OEM
    ; Convert OEM
    xor AX, AX
    mov AL, DH
    call BYTE_TO_HEX
    mov [BX], AX
    ; Print OEM
    mov BX, DX
    mov DX, offset OEM
    call WriteMsg
    ; Get serial number
    mov AL, BL
    mov BX, offset SERIAL
    add BX, OFF_SERIAL
    ; Convert first byte
    call BYTE_TO_HEX
    mov [BX], AX
    add BX, 2
    ; Convert secord byte
    mov AL, CH
    call BYTE_TO_HEX
    mov [BX], AX
    add BX, 2
    ; Convert third byte
    mov AL, CL
    call BYTE_TO_HEX
    mov [BX], AX

    mov DX, offset SERIAL
    call WriteMsg

    pop AX
    pop BX
    pop CX
    pop DX
    ret
MS_DOS_OEM_SERIAL ENDP
BEGIN:
    push  DS
    sub   AX,AX
    push  AX
    ;mov   AX,DATA
    ;mov   DS,AX
    ; Начало
    call TYPE_PC
    call MS_DOS_OEM_SERIAL
    ; Выход
    xor AL,AL
    mov AH,4Ch
    int 21H
    ret

LAB1 ENDS
      END START



