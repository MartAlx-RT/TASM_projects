.model tiny

CMDLNSEG	equ 080h
VIDEOSEG	equ 0b800h
LINE_SIZE	equ 160
LINE_CENTER equ 40
VLINE		equ 0bah
HLINE		equ 0cdh
LT			equ 0c9h
RT			equ 0bbh
LB			equ 0c8h
RB			equ 0bch


.data

.code
org 100h

start:
	mov si, CMDLNSEG
	mov al, [si]	; cmd str length

	sar al, 1		; al /= 2
	mov bl, LINE_CENTER
	sub bl, al
	mov bh, 10

	push bx

	call set_xy
	mov ah, 5dh
	call cmd_cpy

	pop bx

	dec bh
	dec bl
	call set_xy

	mov bl, [si]
	mov bh, 1
	mov ah, 3eh
	call print_box


int 20h

;------------------------------
; es:[di] - offset for copy to 
; ah - color attribute
cmd_cpy:
	mov bx, CMDLNSEG 
	mov cl, [bx]
	add bx, 2

	test cx, cx
	jz _exit_cmd_cpy

	dec cl
	_cpy:
		mov al, [bx]
		mov byte ptr es:[di], al	;symbol from cmd
		inc di

		mov byte ptr es:[di], ah	;color atr
		inc di

		inc bx
	loop _cpy

_exit_cmd_cpy: ret
;------------------------------


;------------------------------
; bl - 'x' (0..80)
; bh - 'y' (0..25)
; sets es:[di] to (x, y)
set_xy:
	mov di, VIDEOSEG
	mov es, di		; set es

	mov ax, LINE_SIZE		; set 'y' offset
	mul bh 

	xor bh, bh
	add ax, bx	; set 'x' offset
	add ax, bx

	mov di, ax
ret
;------------------------------
; bl - width
; bh - height
; ah - color attribute
print_box:
	dec bl
	xor ch, ch

	mov byte ptr es:[di], LT	; left top corner
	inc di
	mov byte ptr es:[di], ah
	inc di

	mov cl, bl
	_top:
		mov byte ptr es:[di], HLINE
		inc di
		mov byte ptr es:[di], ah
		inc di
	loop _top

	mov byte ptr es:[di], RT
	inc di
	mov byte ptr es:[di], ah	; right top corner
	dec di
	add di, LINE_SIZE

	mov cl, bh
	_right:
		mov byte ptr es:[di], VLINE
		inc di
		mov byte ptr es:[di], ah
		dec di
		add di, LINE_SIZE
	loop _right

	mov byte ptr es:[di], RB	; right bottom corner
	inc di
	mov byte ptr es:[di], ah
	sub di, 2

	mov cl, bl
	_bottom:
		mov byte ptr es:[di], ah
		dec di
		mov byte ptr es:[di], HLINE
		dec di
	loop _bottom

	mov byte ptr es:[di], ah	; left bottom corner
	dec di
	mov byte ptr es:[di], LB
	sub di, LINE_SIZE

	mov cl, bh
	_left:
		mov byte ptr es:[di], VLINE
		inc di
		mov byte ptr es:[di], ah
		dec di
		sub di, LINE_SIZE
	loop _left
ret
end	start
