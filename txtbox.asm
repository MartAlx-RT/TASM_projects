.model tiny

locals		@@
;---------------------
CMDLNSEG		equ 080h		; arguments of cmd here
VIDEOSEG		equ 0b800h		; videosegment here
LINE_SIZE		equ 160			; line length in bytes (2 bytes/symbol)
CENTER_POS		equ 80			; center of line in bytes
VLINE			equ 0bah		; symbol that used as vertical line
HLINE			equ 0cdh		; symbol that used as horizontal line
LTOP			equ 0c9h		; left-top corner symbol
RTOP			equ 0bbh		; right-top corner symbol
LBTM			equ 0c8h		; left-bottom corner symbol
RBTM			equ 0bch		; right-bottom corner symbol
CR			equ 0dh

SLP_TIME		equ 10d			; pause time sleeping

V_STARTPOS		equ 5d
;---------------------

.data
	clr_attr	db	3h		; used in print functions as color attribute
	str_buf		db	254d, 260 dup(0); for input text
	box_width	db	20d		; inner width of box (1...70), default width is 20

;------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------
.code
org 100h

start	proc	

	call	atoi
	mov	box_width, bl
@@start:
	call	cls				; clear screen
	
	call	input_str

	; print text

	; print_aligned (cdecl)
	mov	bx, offset str_buf + 2		; bx = str
	xor	ax, ax
	mov	al, byte ptr [bx-1]
	add	ax, bx				; ax = str_end

	sub	bp, 4
	mov	bp, sp

	mov	word ptr [bp], bx		; load s
	mov	word ptr [bp+2], ax		; load s_len

	call	print_aligned
	add	sp, 4

	sub	bx, V_STARTPOS			; now, bx = box height

	; print box around the text

	; set es:[di] to left-top corner
	; cl - string length
	mov	cl, box_width
	; ch - vertical position
	mov	ch, V_STARTPOS-1		; vertical pos = text vertical pos - 1
	call	set_center
	sub	di, 2				; horizontal pos = text horizontal pos - 1 (sub -2 because each symbol is word)

	; print_box (pascal)
	sub	sp, 4
	mov	bp, sp

	xor	ax, ax
	mov	al, box_width
	mov	word ptr [bp+2], ax		; load box width
	mov	word ptr [bp], bx		; load box height

	call	print_box

	; exit
	int 20h
	ret
start	endp

include boxlib.asm
end start
;------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------
