.model tiny

LOCALS		@@
;---------------------
CMDLNSEG	equ 080h
VIDEOSEG	equ 0b800h
LINE_SIZE	equ 160
CENTER_POS	equ 80
VLINE		equ 0bah
HLINE		equ 0cdh
LT			equ 0c9h
RT			equ 0bbh
LB			equ 0c8h
RB			equ 0bch
;---------------------

.data

.code
org 100h

start proc
	mov si, CMDLNSEG
	mov bl, [si]		; write parameters for set_center
	mov bh, 10
	push bx				; and remember it

	call set_center		; set ds:[di]	(points to begginning of writing)
	push di				; remember ds:[di]	(assuming that ds doesn't change)

	mov ah, 35h			; set line color
	call cmd_cpy		; write text

	pop di				; set ds:[di]	(points to begginning of drawing box)
	sub di, (LINE_SIZE+2)

	pop bx				; write parameters for set_center
	mov bh, 1
	mov ah, 3eh			; set line color 
	call print_box

	int 20h
start endp

;-----PRINT TEXT IN PRETTY BOX-
;------------------------------
; si - data
; al - box color attribute
; ah - text color attribute
; bl - 'x' position
; bh - 'y' position
;------------------------------


;-----COPY CMD ARGUMENTS-------
;------------------------------
; es:[di] - offset for copy to 
; ah - color attribute
cmd_cpy proc
	mov bx, CMDLNSEG 
	mov cl, [bx]
	add bx, 2

	test cx, cx
	jz _exit_cmd_cpy

	dec cl
	_cpy:
		mov al, [bx]

		mov byte ptr es:[di], al	;symbol from cmd
		mov byte ptr es:[di+1], ah	;color atr
		add di, 2

		inc bx
	loop _cpy

	_exit_cmd_cpy:
ret
cmd_cpy endp
;------------------------------


; SET ES:[DI] to (bl, bh) ON THE SCREEN
;------------------------------
; bl - 'x' (0..80)
; bh - 'y' (0..25)
; sets es:[di] to (x, y)
set_xy proc
	mov ax, VIDEOSEG
	mov es, ax				; set es

	mov ax, LINE_SIZE		; set 'y' offset (to ax)
	mul bh 

	xor bh, bh
	add ax, bx				; set 'x' offset (to bx)
	add ax, bx

	mov di, ax				; write offset to di (set di)
ret
set_xy endp

; SET ES:[DI] to print centering line
;------------------------------
; bl - string length
; bh - vertical position
; sets es:[di] to print centering line
set_center proc
	mov ax, VIDEOSEG
	mov es, ax				; set es

	mov ax, LINE_SIZE		; set 'y' offset (to ax)
	mul bh

	xor bh, bh

	add ax, CENTER_POS		; position = center - (strlen/2)*2	[*2, because attribute and bytes]
	sub ax, bx

	mov di, ax
ret
set_center endp


; PRINT BOX WITH LEFT-TOP AT ES:[DI]
;------------------------------
; es:[di] - left-top position
; bl - width
; bh - height
; ah - color attribute
print_box proc
	dec bl
	xor ch, ch

	mov byte ptr es:[di], LT		; draw left top corner
	mov byte ptr es:[di+1], ah
	add di, 2

	mov cl, bl
	_top:							; draw top line
		mov byte ptr es:[di], HLINE
		mov byte ptr es:[di+1], ah
		add di, 2
	loop _top

	mov byte ptr es:[di], RT
	mov byte ptr es:[di+1], ah		; draw right top corner
	add di, LINE_SIZE

	mov cl, bh
	_right:							; draw right line
		mov byte ptr es:[di], VLINE
		mov byte ptr es:[di+1], ah
		add di, LINE_SIZE
	loop _right

	mov byte ptr es:[di], RB		; draw right bottom corner
	mov byte ptr es:[di+1], ah
	sub di, 2

	mov cl, bl
	_bottom:						; draw bottom line
		mov byte ptr es:[di], HLINE
		mov byte ptr es:[di+1], ah
		sub di, 2
	loop _bottom

	mov byte ptr es:[di], LB
	mov byte ptr es:[di+1], ah		; draw left bottom corner
	sub di, LINE_SIZE

	mov cl, bh
	_left:							; draw left line
		mov byte ptr es:[di], VLINE
		mov byte ptr es:[di+1], ah
		sub di, LINE_SIZE
	loop _left
ret
print_box endp

end start
