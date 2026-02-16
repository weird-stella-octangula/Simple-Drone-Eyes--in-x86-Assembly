org 100h
use16
WIDTH equ 80
HEIGHT equ 25
MAGENTA equ 5
BRIGHT_YELLOW equ 14
RED equ 4

EYE_CHAR equ '*'
START_X equ 15
START_Y equ 10

BROW_CHAR equ "_"
EYE_DIST equ 15
EYE_SIZE equ 6
EYE_MOVE equ 2
BROW_SIZE equ EYE_SIZE*2
BROW_OFFSET equ 2
REPEAT equ 2
_start:
	mov bx,0xb800
	mov es,bx

	mov ax,3
	int 10h
	
	mov ah,9		;DOS Int 21(AH =9) PRINTS STRING
	mov dx,guide1		;TERMINATED WITH "$"
	int 21h			;DS:DX = POINTER TO STR
	mov dx,guide2
	int 21h
	mov dx,guide3
	int 21h
	mov dx,prompt
	int 21h

input:
	mov ah,07
	int 21h

	cmp al,'u'
	jz purple
	cmp al,'n'
	jz yellow
	cmp al,'d'
	jz red
	cmp al,27
	jz prog_end
	
	jmp input

purple:
	mov [color],MAGENTA
	jmp func_call

yellow:
	mov [color],BRIGHT_YELLOW
	jmp func_call

red:
	mov [color],RED

func_call:
	
	push ax
	mov ax,0x3
	int 0x10
	pop ax

	mov al,[color]
	call changeColor

	call drawEyes
	call drawBrow
	

anim_loop:

	inc [browY]
	call drawBrow
	mov ax,0x8600	;BIOS Delay (100 ms)
	mov cx,1	;(CX:DX) = Delay in micro-seconds
	mov dx,0x86A0
	int 15h
	cmp [browY],START_Y + EYE_SIZE - BROW_OFFSET
	jl anim_loop
	
	mov ax,0x8600
	mov cx,3	;Delay (200 ms)
	mov dx,0x0d40
	int 0x15
	
.anim_up:
	mov [browChar],0
	call drawBrow
	dec [browY]
	call drawEyes
	mov [browChar],BROW_CHAR
	call drawBrow
	cmp [browY],START_Y - BROW_OFFSET
	mov ax,0x8600
	mov cx,1
	mov dx,0x86A0	
	int 0x15
	jg .anim_up

	mov ax,0x8600
	mov cx,3	;Delay (200 ms)
	mov dx,0x0d40
	int 0x15

	mov [eyeChar],0
	call drawEyes
	mov [eyeChar],EYE_CHAR
	sub [xPos],EYE_MOVE
	call drawEyes
	
	mov ax,0x8600
	mov cx,4
	mov dx,0x93e0
	int 0x15

	mov cx,2
.anim_right:
 	push cx
	mov ax,0x8600
	mov cx,3	;Delay (200 ms)
	mov dx,0x0d40
	int 0x15
	
	mov [eyeChar],0
	call drawEyes
	mov [eyeChar],EYE_CHAR
	add [xPos],EYE_MOVE
	call drawEyes

	mov ax,0x8600
	mov cx,7
	mov dx,0xA120	;Delay(500 ms)
	int 0x15
	pop cx
	loop .anim_right

	mov [eyeChar],0
	call drawEyes
	mov [eyeChar],EYE_CHAR
	mov [xPos],START_X
	call drawEyes

	mov ax,0x8600
	mov cx,3	;Delay (200 ms)
	mov dx,0x0d40
	int 0x15


prog_end:
	int 0x20

;FUNCTIONS:------------------------------------------------------------------------------
;FUNCTION:ChangeColor
changeColor:	;AL = Color
	pusha
	mov di,1
.fill:
	stosb
	inc di
	cmp di,1
	jnz .fill

	popa
	ret
;FUNCTION:PLACECHAR
placeChar: ;Uses EyeChar: AH=X;AL = Y
	cmp ah,0
	jl .prog_end
	cmp al,0
	jl .prog_end
	cmp ah,WIDTH
	jg .prog_end
	cmp al,HEIGHT
	jg .prog_end
	pusha
	xor dx,dx ;DX = 0
	mov dl,ah ;DL = X
	mov dh,WIDTH ;DH = 80
	mul dh	 ;AX = AL * DH;AX = Y*80
	mov dh,0  ;DH = 0;DX = DL
	add ax,dx ;AX = AX + DX;AX = Y*80 + X
	shl ax,1
	mov di,ax
	mov bl,[eyeChar]
	mov byte[es:di],bl
	popa
.prog_end:
	ret

;FUNCTION:DrawEyes
drawEyes:
	pusha
	mov dx,1 ;offset each iteration
	mov cx,2 ;repeated stars
	mov bx,2 ;Temporary holder for CX
	mov ah,[xPos]
	mov al,[yPos]
.print:
	call placeChar
	add ah,EYE_DIST
	call placeChar
	sub ah,EYE_DIST ;Mirroring
	
	inc ah		;Move to the right(x++)
	loop .print
	cmp bx,EYE_SIZE*2	;Compares if we reached the meat ;)
	jge .print2_set
	mov ah,[xPos]
	sub ah,dl
	inc al
	inc dl
	mov cx,bx
	add cx,2
	mov bx,cx
	jmp .print
	
.print2_set:
	inc al
	mov ah,[xPos]
	sub dl,2
	mov cx,bx
	sub cx,2
	mov bx,cx
	sub ah,dl
	dec dl
.print2:
	call placeChar
	add ah,EYE_DIST
	call placeChar
 	sub ah,EYE_DIST
	inc ah
	loop .print2
	cmp bx,2
	jle drawEyes_end
	mov ah,[xPos]
	sub ah,dl
	inc al
	dec dl
	mov cx,bx
	sub cx,2
	mov bx,cx
	jmp .print2
drawEyes_end:
	popa
	ret

;FUNCTION:DRAWBROW
drawBrow:
	pusha
	mov bx,0
	mov ax,0
	
	mov al,[browY]
	mov bl,80
	mul bl
	mov bl,[browX]
	add ax,bx
	mov bx,2
	mul bx
	mov bx,ax	
	
	mov ax,0
	mov al,0
	mov di,0
.shaveTop:
	stosb
	inc di
	cmp di,bx
	jnz .shaveTop
.brow_continue:
	mov ax,di
	add ax,EYE_SIZE*4 + EYE_DIST*2
	mov bx,di
	add bx,BROW_SIZE*2
.makeTop:
	mov dl,[browChar]
	mov byte[es:di],dl
	add di,EYE_DIST*2
	mov byte[es:di],dl
	sub di,EYE_DIST*2
	inc di
	inc di
	cmp di,bx
	jnz .makeTop
	popa
	ret
guide1 db "u-Uzi",10,13,"$"
guide2 db "n-N/V/J/Cyn...",10,13,"$"
guide3 db "d-Doll",10,13,"$"
prompt db "Enter color:","$"
xPos db START_X
yPos db START_Y
browX db START_X-EYE_SIZE + 1
browY db START_Y - BROW_OFFSET
browChar db BROW_CHAR
eyeChar db EYE_CHAR
color db 0
