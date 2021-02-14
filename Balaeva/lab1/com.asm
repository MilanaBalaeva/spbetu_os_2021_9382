TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC
   ORG 100H
START: JMP BEGIN
; Данные
PC_T db  'My type: PC',0DH,0AH,'$'
PC_XT_T db 'My type: PC/XT',0DH,0AH,'$'
AT_T db  'My type: AT',0DH,0AH,'$'
PS2_M30_T db 'MY type: PS2 модель 30',0DH,0AH,'$'
PS2_M50_60_T db 'My type: PS2 модель 50 или 60',0DH,0AH,'$'
PS2_M80_T db 'My type: PS2 модель 80',0DH,0AH,'$'
PС_JR_T db 'My type: PСjr',0DH,0AH,'$'
PC_CONV_T db 'My type: PC Convertible',0DH,0AH,'$'

VERSION db 'Version MS-DOS:  .  ',0DH,0AH,'$'
SERIAL db  'Serial number OEM:  ',0DH,0AH,'$'
USER db  'User serial number:       H $'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
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
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
PC_TYPE PROC near
   mov ax, 0f000h ; 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh ; 
	je pc
	cmp al, 0feh
	je xt
	cmp al, 0fbh
	je xt
	cmp al, 0fch
	je at
	cmp al, 0fah
	je ps2_m30
	cmp al, 0f8h
	je ps2_m80
	cmp al, 0fdh
	je jr
	cmp al, 0f9h
	je conv
pc:
		mov dx, offset PC_T
		jmp writetype
xt:
		mov dx, offset PC_XT_T
		jmp writetype
at:
		mov dx, offset AT_T
		jmp writetype
ps2_m30:
		mov dx, offset PS2_M30_T
		jmp writetype
ps2_m50_60:
		mov dx, offset PS2_M50_60_T
		jmp writetype
ps2_m80:
		mov dx, offset PS2_M80_T
		jmp writetype
jr:
		mov dx, offset PС_JR_T
		jmp writetype
conv:
		mov dx, offset PC_CONV_T
		jmp writetype
writetype:
		mov AH,09h
   		int 21h
	ret
PC_TYPE ENDP

OS_VER PROC near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VERSION
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSION
	mov AH,09h
   	int 21h
	
	mov si, offset SERIAL
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL
	mov AH,09h
   	int 21h
	
	mov di, offset USER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER
	mov AH,09h
   	int 21h
	ret
OS_VER ENDP

; Код
BEGIN:
   call PC_TYPE
   call OS_VER

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START
