TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC
 ORG 100H
 START: JMP BEGIN
OFF_ db 'Segment address of the first byte of inaccessible memory: '
OFF db '    ',0DH,0AH,'$'
SEGSR_ db 'Segmental address of the environment passed to the program: '
SEGSR db '    ',0DH,0AH,'$'
tail_ db 'Command-line tail: ',0DH,0AH,'$'
MED_ db 'The contents of the environment area in the symbolic form: ',0DH,0AH,'$'
PATH_ db 'Load module path: ',0DH,0AH,'$'
ENDL db 0DH,0AH,'$'
;--------------------------------------
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
;---------------------------------------
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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;---------------------------------------
WRITEMSG PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
WRITEMSG ENDP
;---------------------------------------
GET_ADRESS_OFF PROC
	mov ax,es:[2]
	mov di,offset OFF+3
	call WRD_TO_HEX
	lea dx,OFF_
	call WRITEMSG
	ret
GET_ADRESS_OFF ENDP	
;---------------------------------------
GET_SEGSR PROC
	mov ax,es:[2Ch]
	mov di,offset SEGSR+3
	call WRD_TO_HEX
	lea dx,SEGSR_
	call WRITEMSG
	ret
GET_SEGSR  ENDP
;---------------------------------------
TAIL PROC NEAR
	push ax
	push cx
	push dx
	push si
	push di

  ;Получение хвоста командной строки
  mov bx,080h
  xor cx,cx
  mov cl,[bx]
  mov ah,02h
  mov si,081h
  test cx,cx
  jz end1
  ;Если хвост отсутствует
get_tail:
  lodsb
  mov dl,al
  int 21h
  loop get_tail
end1:
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
TAIL ENDP
;--------------------------------------
MED PROC
	mov dx,offset MED_
	call WRITEMSG
	push es
	mov ax,es:[2Ch]
	mov es,ax
	mov ah,02h
	mov bx,0
	MED_loop:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne MED_loop
		mov dx,offset ENDL
		call WRITEMSG
		cmp word ptr es:[bx],0000h
		jne MED_loop
		
	add bx,4 
	mov dx,offset PATH_
	call WRITEMSG
	
	MED_loop2:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne MED_loop2
	mov dx,offset ENDL
	call WRITEMSG
	
	pop es
	ret
MED ENDP

BEGIN:
	call GET_ADRESS_OFF
	call GET_SEGSR
	call TAIL
	call MED
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START 


