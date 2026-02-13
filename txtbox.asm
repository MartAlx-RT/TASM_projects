.model tiny

locals		@@
;---------------------
CMDLNSEG		equ 080h
VIDEOSEG		equ 0b800h
LINE_SIZE		equ 160
CENTER_POS		equ 80
VLINE			equ 0bah
HLINE			equ 0cdh
LTOP			equ 0c9h
RTOP			equ 0bbh
LBTM			equ 0c8h
RBTM			equ 0bch

SLP_TIME		equ 10
;---------------------

.data

.code
org 100h

start proc
	call cls

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

;---PRINT TEXT IN PRETTY BOX---
;------------------------------
; si - data
; al - box color attribute
; ah - text color attribute
; bl - 'x' position
; bh - 'y' position
;------------------------------
; sorry, not implemented

;-----COPY CMD ARGUMENTS-------
;------------------------------
; es:[di] - offset for copy to 
; ah - color attribute
cmd_cpy proc
	mov bx, CMDLNSEG 
	mov cl, [bx]					; cx = strlen, set bx to beginning of the line
	add bx, 2

	test cx, cx
	jz @@exit_cmd_cpy

	dec cl
	@@cpy:
		mov al, [bx]

		mov byte ptr es:[di], al	; cp symbol from cmd to screen
		mov byte ptr es:[di+1], ah	; set color attribute
		add di, 2

		inc bx

		call pause					; pause
	loop @@cpy

	@@exit_cmd_cpy:
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
	and bl, 11111110b		; set lowest bit to zero (aligning)

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
	test bl, bl
	jz @@exit_print_box

	dec bl
	xor ch, ch						; correcting width && set counter (cx) to zero

	mov byte ptr es:[di], LTOP		; draw left top corner
	mov byte ptr es:[di+1], ah
	add di, 2

	mov cl, bl
	@@top:							; draw top line
		mov byte ptr es:[di], HLINE
		mov byte ptr es:[di+1], ah
		add di, 2
	loop @@top

	mov byte ptr es:[di], RTOP
	mov byte ptr es:[di+1], ah		; draw right top corner
	add di, LINE_SIZE

	mov cl, bh
	@@right:						; draw right line
		mov byte ptr es:[di], VLINE
		mov byte ptr es:[di+1], ah
		add di, LINE_SIZE
	loop @@right

	mov byte ptr es:[di], RBTM		; draw right bottom corner
	mov byte ptr es:[di+1], ah
	sub di, 2

	mov cl, bl
	@@bottom:						; draw bottom line
		mov byte ptr es:[di], HLINE
		mov byte ptr es:[di+1], ah
		sub di, 2
	loop @@bottom

	mov byte ptr es:[di], LBTM
	mov byte ptr es:[di+1], ah		; draw left bottom corner
	sub di, LINE_SIZE

	mov cl, bh
	@@left:							; draw left line
		mov byte ptr es:[di], VLINE
		mov byte ptr es:[di+1], ah
		sub di, LINE_SIZE
	loop @@left

	@@exit_print_box:
ret
print_box endp

;---PAUSE FOR SLP_TIME---
pause proc
	push ax cx dx

	mov ah, 86h
	mov cx, SLP_TIME
	
	int 15h

	pop dx cx ax
ret
pause endp

;---CLEAR SHELL---
cls proc
	push ax

	xor ah, ah
	mov al, 03h
	int 10h

	pop ax
ret
cls endp

end start
