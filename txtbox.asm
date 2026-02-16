.model tiny

locals		@@
;---------------------
CMDLNSEG		equ 080h		; arguments of cmd here
VIDEOSEG		equ 0b800h		; videosegment here
LINE_SIZE		equ 160			; line length in bytes (2 bytes/symbol)
CENTER_POS		equ 80			; center of line in bytes
VLINE			equ 0bah		; symbol that used as vertical line
HLINE			equ 0cdh		; -----\\---\\---- as horizontal line
LTOP			equ 0c9h		; left-top corner symbol
RTOP			equ 0bbh		; right-top ---\\---\\--
LBTM			equ 0c8h		; left-bottom ---\\---\\--
RBTM			equ 0bch		; right-bottom ---\\---\\--

SLP_TIME		equ 10d			; pause time sleeping

BOX_WIDTH		equ 20d
V_STARTPOS		equ 5d
;---------------------

.data
	clr_attr	db	3h
	str_buf		db	254d, 260 dup(0)
.code
org 100h

start proc
	call cls					; clear screen

	mov ah, 0ah
	mov dx, offset str_buf		; input text
	int 21h

	mov si, offset str_buf + 2
	mov cl, byte ptr [si-1]		; print aligning text
	xor ch, ch
	call aligned_print

	;int 20h
	mov cl, BOX_WIDTH+2
	mov ch, V_STARTPOS - 1		; set es:[di] to left-top corner
	call set_center

	mov bx, bp
	sub bx, V_STARTPOS
	mov bh, bl					; print box around the text
	mov bl, BOX_WIDTH
	call print_box

	int 20h
start endp

;-----COPY CMD ARGUMENTS-------
;------------------------------
; es:[di] - offset for copy to 
; used clr_attr
;------------------------------
; DESTR: ax, bx, cx and input parameters
cmd_cpy proc
	mov ah, clr_attr

	mov bx, CMDLNSEG 
	mov cl, [bx]					; cx = strlen, set bx to beginning of the line
	xor ch, ch
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
;------------------------------
; DESTR: ax, dx and input parameters
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
; cl - string length
; ch - vertical position
; sets es:[di] to print centering line
;------------------------------
; DESTR: ax, dx and input parameters
set_center proc
	mov ax, VIDEOSEG
	mov es, ax				; set es

	mov ax, LINE_SIZE		; set 'y' offset (to ax)
	mul ch

	xor ch, ch
	and cl, 11111110b		; set lowest bit to zero (aligning)

	add ax, CENTER_POS		; position = center - (strlen/2)*2	[*2, because attribute and bytes]
	sub ax, cx

	mov di, ax
ret
set_center endp


; PRINT BOX WITH LEFT-TOP AT ES:[DI]
;------------------------------
; es:[di] - left-top position
; bl - width
; bh - height
; used clr_attr
;------------------------------
; DESTR: cx, ax and input parameters
print_box proc
	mov ah, clr_attr

	test bl, bl
		jz @@exit_print_box			; if you wanna print empty box, go fuck yourself

	;dec bl
	xor ch, ch						; correcting width && set counter (cx) to zero

	;mov byte ptr es:[di], LTOP		; draw left top corner
	;mov byte ptr es:[di+1], ah
	;add di, 2
	cld
	mov al, LTOP
	stosw

	mov cl, bl
	mov al, HLINE
	;@@top:							; draw top line
	;	mov byte ptr es:[di], HLINE
	;	mov byte ptr es:[di+1], ah
	;	add di, 2
	;loop @@top
	rep stosw

	;mov byte ptr es:[di], RTOP
	;mov byte ptr es:[di+1], ah		; draw right top corner
	mov al, RTOP
	stosw
	add di, LINE_SIZE-2				; -2 because 'stosw' adds 2 to di

	mov cl, bh
	mov al, VLINE
	@@right:						; draw right line
		;mov byte ptr es:[di], VLINE
		;mov byte ptr es:[di+1], ah
		stosw
		add di, LINE_SIZE-2
	loop @@right

	std
	;mov byte ptr es:[di], RBTM		; draw right bottom corner
	;mov byte ptr es:[di+1], ah
	;sub di, 2
	mov al, RBTM
	stosw

	mov cl, bl
	mov al, HLINE
	rep stosw
	;@@bottom:						; draw bottom line
	;	mov byte ptr es:[di], HLINE
	;	mov byte ptr es:[di+1], ah
	;	sub di, 2
	;loop @@bottom

	mov al, LBTM
	;mov byte ptr es:[di], LBTM
	;mov byte ptr es:[di+1], ah		; draw left bottom corner
	stosw
	sub di, LINE_SIZE-2

	mov cl, bh
	mov al, VLINE
	@@left:							; draw left line
		;mov byte ptr es:[di], VLINE
		;mov byte ptr es:[di+1], ah
		stosw
		sub di, LINE_SIZE-2
	loop @@left

	@@exit_print_box:
ret
print_box endp

;------PAUSE FOR SLP_TIME------
;---------nothing destroys-----
pause proc
	push ax cx dx

	mov ah, 86h
	mov cx, SLP_TIME
	
	int 15h

	pop dx cx ax
ret
pause endp

;-------CLEAR SHELL------------
;------nothing destroys--------
cls proc
	push ax

	xor ah, ah
	mov al, 03h
	int 10h

	pop ax
ret
cls endp

;--PRINT CENTER-ALIGNED TEXT---
; si - source text
; cx - length of text
; used clr_attr
; Destr: ax, bx, dx, di, bp, es and input parameters
aligned_print proc
	;mov bx, si					; use bx for addressing
	;add bx, cx					; set bx to end of str

	;mov ax, 0ffffh				; 0ffffh - is the 'end' value, used as terminating value
	;push ax						; push 'end' value to end of stack
	;push bx

	;@@parse:					; parce (find and push) spaces
	;	cmp byte ptr [bx], ' '
	;		jne @@parse_continue
	;	push bx

	;	@@parse_continue:
	;	dec bx
	;	cmp bx, si				; untill line beginning reached
	;		jg @@parse
	;;end parse

	;----------------------------------------------------------------------------------
	mov bp, V_STARTPOS			; begin with V_STARTPOS line, bx - vertical position

	mov bx, si	;				\-\-\-\-\-\-\-\-\-\-\
	mov dx, si	;				 \       \       \
				;				 si      dx      bx
	;           				start  old new   finding new
	@@print_line:
		mov si, dx
	;	@@pop_spc:				; how many spaces is it possible to skip
	;		mov cx, dx			; how many spaces is it possible to skip
	;		pop dx				; dx = next space position

	;		mov ax, dx
	;		sub ax, si
	;		cmp ax, BOX_WIDTH	; less than BOX_WIDTH?
	;			jb @@pop_spc	; if less, it may possible to print another word
	;	; end pop_spc

		;push dx cx
		@@max_seq:
			mov dx, bx

			@@find_space:
				inc bx

				cmp byte ptr [bx], 0
			jz @@exit_print
				cmp byte ptr [bx-1], ' '
			jne @@find_space

			mov ax, bx
			sub ax, si
			cmp ax, BOX_WIDTH
		jb @@max_seq

		jmp @@exit_print_last_line
		@@exit_print:
		mov dx, bx
		@@exit_print_last_line:

		mov ax, dx
		sub ax, si				; now, ax = len
		;test cx, cx
		;	jz @@exit_print		; len = 0 => exit
		;inc cx					; correcting length

		;push cx
		;mov ax, bx
		;mov ch, al
		;call set_center			; set es:[di] to print aligned line
		;pop cx

		push dx bx ax

		mov cl, al
		mov ax, bp
		mov ch, al
		call set_center
		
		pop cx
		call strncpy			; copy current line to vram
		inc bp					; vertical position ++

		pop bx dx

		cmp byte ptr [bx], 0
	jnz @@print_line

ret
aligned_print endp


;--COPY N BYTES FROM SI TO VIDEO--
; si - source string
; cx - strlen
; used clr_attr
; es:[di] - address for copy to
; Destr: ax
strncpy proc
	mov ah, clr_attr
	
	test cx, cx
		jz @@strncpy_exit			; length = 0 => exit
	dec cx							; correct length
	@@cpy_loop:
		mov al, byte ptr [si]
		;mov byte ptr es:[di], al
		;mov byte ptr es:[di+1], ah
		stosw

		;add di, 2
		inc si
	loop @@cpy_loop

	@@strncpy_exit:
ret
strncpy endp

end start
