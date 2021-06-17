CODE SEGMENT
ASSUME  DS:CODE, CS:CODE, SS:CODE, ES:CODE
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ
	er db 'Ошибка: $'
	er1 db 'Номер функции неверен$'
	er2 db 'Файл не найден$'
	er7 db 'Разрушен управляющий блок памяти$'
	er8 db 'Недостаточный объем памяти$'
	er9 db 'Неверный адрес блока памяти$'
	er10 db 'Неправильная строка среды$'
	er11 db 'Неправильный формат$'
	
	; причины завершения
	end0 db 'Нормальное завершение$'
	end1 db 'Завершение по Ctrl-Break$'
	end2 db 'Завершение по ошибке устройства$'
	end3 db 'Завершение по функции 31h$'
	end_cod db 'Код завершения: $'
	t_code  db 0	
	STRENDL db 0DH,0AH,'$'
	
	; блок параметров
	ARG 	dw 0 ; сегментный адрес среды
			dd 0 ; сегмент и смещение командной строки
			dd 0 ; сегмент и смещение первого FCB
			dd 0 ; сегмент и смещение второго FCB
	
	; путь и имя вызываемой программы	
	PROGR db 40h dup (0)
	; переменные для хранения SS и SP
	KEEP_SS dw 0
	KEEP_SP dw 0
	TStack  db 100h dup(0) 
; ПРОЦЕДУРЫ
;---------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
PRINT PROC
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
PREP PROC
	 mov BX,offset prog_end   
     mov cl, 4    
     shr bx,cl
     inc bx
     mov ah,4Ah
     int 21h
	jnc PREP_skip1
		call PROC_ER
	PREP_skip1:
	
	; подготавливаем блок параметров:
	call PREP_PAR
	
	; определяем путь до программы:
	push es
	push bx
	push si
	push ax
	mov es,es:[2ch] ; в es сегментный адрес среды
	mov bx,-1
	SREDA_ZIKL:
		add bx,1
		cmp word ptr es:[bx],0000h
		jne SREDA_ZIKL
	add bx,4
	mov si,-1
	PUT_ZIKL:
		add si,1
		mov al,es:[bx+si]
		mov PROGR[si],al
		cmp byte ptr es:[bx+si],00h
		jne PUT_ZIKL
	
	add si,1
	PUT_ZIKL2:
		mov PROGR[si],0
		sub si,1
		cmp byte ptr es:[bx+si],'\'
		jne PUT_ZIKL2
	add si,1
	mov PROGR[si],'l'
	add si,1
	mov PROGR[si],'a'
	add si,1
	mov PROGR[si],'b'
	add si,1
	mov PROGR[si],'2'
	add si,1
	mov PROGR[si],'.'
	add si,1
	mov PROGR[si],'c'
	add si,1
	mov PROGR[si],'o'
	add si,1
	mov PROGR[si],'m'
	pop ax
	pop si
	pop bx
	pop es	
	
	ret
PREP ENDP
;---------------------------------------
PREP_PAR PROC
	mov ax, es:[2ch]
	mov ARG, ax
	mov ARG+2,es ; Сегментный адрес параметров командной строки(PSP)
	mov ARG+4,80h ; Смещение параметров командной строки
	ret
PREP_PAR ENDP
;---------------------------------------
START_MOD PROC
	
	mov ax,ds
	mov es,ax
	mov bx,offset ARG
	
	
	mov dx,offset PROGR
	
	
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	
	
	mov ax,4B00h
	mov al, 0h
    int 21h
	
	
	mov cx, cs
    mov ds, cx
    mov es, cx
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	jnc START_MOD_skip1
		call PROC_ER
		jmp START_MOD_konec
	START_MOD_skip1:
	
	
	call ENTER_END
	
	START_MOD_konec:

	ret
START_MOD ENDP
;---------------------------------------
PROC_ER PROC
	mov dx,offset er
	call PRINT

	mov dx,offset er1
	cmp ax,1
	je osh_pechat
	mov dx,offset er2
	cmp ax,2
	je osh_pechat
	mov dx,offset er7
	cmp ax,7
	je osh_pechat
	mov dx,offset er8
	cmp ax,8
	je osh_pechat
	mov dx,offset er9
	cmp ax,9
	je osh_pechat
	mov dx,offset er10
	cmp ax,10
	je osh_pechat
	mov dx,offset er11
	cmp ax,11
	je osh_pechat
	
	osh_pechat:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	ret
PROC_ER ENDP
;---------------------------------------
ENTER_END PROC
	; получаем в al код завершения, в ah - причину:
	mov al,00h
	mov ah,4dh
	int 21h

	mov dx, offset end0
	cmp ah, 0
	je ENTER_END_pech_1
	mov dx,offset end1
	cmp ah,1
	je ENTER_END_pech
	mov dx,offset end2
	cmp ah,2
	je ENTER_END_pech
	mov dx,offset end3
	cmp ah,3
	je ENTER_END_pech
	
	ENTER_END_pech_1:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	mov dx, offset end_cod
	
	ENTER_END_pech:
	call PRINT

	cmp ah,0
	jne ENTER_END_skip

	; печать кода завершения:
	mov dl,al
	mov ah,02h
	int 21h

;call BYTE_TO_HEX
;	push ax
;	mov ah,02h
;	mov dl,al
;	int 21h
;	pop ax
;	mov dl,ah
;	mov ah,02h
;	int 21h
	mov dx,offset STRENDL
	call PRINT
	ENTER_END_skip:
	
	ret

ENTER_END ENDP
;---------------------------------------
BEGIN:
	mov sp, offset TStack
    add sp, 100h
	call PREP
	call START_MOD
	xor AL,AL
	mov AH,4Ch
	int 21H
prog_end:
CODE ENDS
 END START