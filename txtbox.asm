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

V_STARTPOS		equ 5d
;---------------------

.data
	clr_attr	db	3h					; used in print functions as color attribute
	str_buf		db	254d, 260 dup(0)	; for input text
	box_width	db	20d					; inner width of box (1...70), default width is 20

;------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------
.code
org 100h


start proc

	; parsing cmd arguments (now only can parse two-digital numers)
	mov bx, CMDLNSEG
	cmp byte ptr [bx], 0
je @@start								; if program runned without arguments, start with default options

	sub word ptr [bx+2], '0' + '0'*100h	; convertion ascii to 2-digitals number
	mov al, byte ptr [bx+2]				; al = (highest digit)
	mov cl, 10d
	mul cl								; cl = cl*10 + (lower digit)
	add al, byte ptr [bx+3]

	mov box_width, al					; set box_width

@@start:
	call cls					; clear screen
	
	call input_str

	; print text

	; si - source text
	mov si, offset str_buf+2
	; cx - length of text
	mov cl, byte ptr [si-1]		; print aligning text
	xor ch, ch
	call print_aligned
	sub bx, V_STARTPOS			; now, bx = box height

	; print box around the text

	; set es:[di] to left-top corner
	; cl - string length
	mov cl, box_width
	; ch - vertical position
	mov ch, V_STARTPOS-1		; vertical pos = text vertical pos - 1
	call set_center
	sub di, 2					; horizontal pos = text horizontal pos - 1 (sub -2 because each symbol is word)

	; print_box (used cdecl convention)
	sub sp, 4
	mov bp, sp

	xor ax, ax
	mov al, box_width
	mov word ptr [bp+2], ax		; load box width
	mov word ptr [bp], bx		; load box height

	call print_box
	add sp, 4

	; exit
	int 20h
	ret
start endp

include boxlib.asm
end start
;------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------
