;------------------------------------------------------
;-----------------INPUT_STR FUNCTION-------------------
; input string from stdin && add	0 at the end (asciz)
;-------------------EXPECTED---------------------------
; used str_buf
;-------------------RETURNS----------------------------
; writes input string to str_buf
;-------------------DESTROYS---------------------------
; ax, dx and input parameters
;------------------------------------------------------
input_str	proc	
	mov	ah, 0ah
	mov	dx, offset str_buf	; input text
	int	21h

	xor	ax, ax

	mov	bx, offset str_buf+2
	mov	al, byte ptr [bx-1]	; ax = strlen
	add	bx, ax			; bx = end of str

	mov	byte ptr [bx], 0	; add	0 to the end of the string
	ret
input_str	endp




;------------------------------------------------------
;-----------------SET_XY FUNCTION----------------------
; SETS ES:[DI] to (bl, bh) ON THE SCREEN
;-------------------EXPECTED---------------------------
; bl - 'x' (0..80)
; bh - 'y' (0..25)
;-------------------RETURNS----------------------------
; sets es:[di] to (x, y)
;-------------------DESTROYS---------------------------
; ax, dx and input parameters
;------------------------------------------------------
set_xy	proc	
	mov	ax, VIDEOSEG
	mov	es, ax		; set es

	mov	ax, LINE_SIZE	; set 'y' offset (to ax)
	mul	bh 

	xor	bh, bh
	add	ax, bx		; set 'x' offset (to bx)
	add	ax, bx

	mov	di, ax		; write offset to di (set di)
	ret
set_xy	endp




;------------------------------------------------------
;-----------------SET_CENTER FUNCTION------------------
; SETS ES:[DI] to (bl, bh) TO PRINT CENTERING
;-------------------EXPECTED---------------------------
; cl - string length
; ch - vertical position
;-------------------RETURNS----------------------------
; sets es:[di] to print	centering line
;-------------------DESTROYS---------------------------
; ax, dx and input parameters
;------------------------------------------------------
set_center	proc	
	mov	ax, VIDEOSEG
	mov	es, ax		; set es

	mov	ax, LINE_SIZE	; set 'y' offset (to ax)
	mul	ch

	xor	ch, ch
	and	cl, not 01b	; set lowest bit to zero (aligning)

	add	ax, CENTER_POS	; position = center - (strlen/2)*2	[*2, because attribute and bytes]
	sub	ax, cx

	mov	di, ax
	ret
set_center	endp




;------------------------------------------------------
;-----------------PRINT_BOX  FUNCTION------------------
; SETS ES:[DI] to (bl, bh) TO PRINT CENTERING
;-------------------EXPECTED---------------------------
; !! PASCAL CONVENTION !!
; 1st arg(word) - box width
; 2nd arg(word) - box height
; used clr_attr
;-------------------RETURNS----------------------------
; prints box with left-top at es:[di]
;-------------------DESTROYS---------------------------
; cx, ax and input parameters
;------------------------------------------------------
print_box	proc	
	push	bp
	mov	bp, sp

	mov	ah, clr_attr

	cmp	word ptr [bp+6], 0
	jz	@@terminate_print_box	; if you wanna print	empty box, go fuck yourself

	xor	cx, cx			; set counter (cx) to zero

	cld				; forward 'stosw' mode

	mov	al, LTOP		; draw left-top corner
	stosw

	mov	cx, [bp+6]
	mov	al, HLINE		; draw upper horizontal line
	rep	stosw

	mov	al, RTOP		; draw right-top corner
	stosw
	add	di, LINE_SIZE-2		; -2 because 'stosw' adds 2 to di

	mov	cx, [bp+4]
	mov	al, VLINE
@@right:				; draw right line
	stosw
	add	di, LINE_SIZE-2
loop	@@right

	std				; reverse 'stosw' mode

	mov	al, RBTM		; draw right-bottom corner
	stosw

	mov	cx, [bp+6]
	mov	al, HLINE		; draw lower horizontal line
	rep	stosw
	
	mov	al, LBTM		; draw left-bottom corner
	stosw
	sub	di, LINE_SIZE-2

	mov	cx, [bp+4]
	mov	al, VLINE
@@left:					; draw left line
	stosw
	sub	di, LINE_SIZE-2
loop	@@left

@@terminate_print_box:
	pop	bp
	ret	4
print_box	endp




;------------------------------------------------------
;-----------------PAUSE      FUNCTION------------------
; wait for SLP_TIME microseconds
;-------------------EXPECTED---------------------------
; used SLP_TIME
;-------------------RETURNS----------------------------
;-------------------DESTROYS---------------------------
; nothing
;------------------------------------------------------
pause	proc	
	push	ax cx dx

	mov	ah, 86h
	mov	cx, SLP_TIME
	
	int	15h

	pop	dx cx ax
	ret
pause	endp

;------------------------------------------------------
;-----------------CLEAR SHELL FUNCTION-----------------
; clears the screen and set default video-mode (number 3)
;-------------------EXPECTED---------------------------
;-------------------RETURNS----------------------------
; cleared screen =)
;-------------------DESTROYS---------------------------
; nothing
;------------------------------------------------------
cls	proc	
	push	ax cx es di

	mov	cx, 80*25
	mov	ax, VIDEOSEG
	mov	es, ax
	xor	di, di
	xor	ax, ax
	mov	ah, 07h
	cld
	rep	stosw

	pop	di es cx ax
	ret
cls	endp




;------------------------------------------------------
;-----------------PRINT_ALIGNED FUNCTION---------------
; prints center-aligned text
;-------------------EXPECTED---------------------------
; !! CDECL CONVENTION !!
; 1st arg (word) - beginning of the string
; 2nd arg (word) - end of the string
; used clr_attr
; beginning with V_STARTPOS line
;-------------------RETURNS----------------------------
; bp - last line position
;-------------------DESTROYS---------------------------
; ax, bx, dx, di, bp, es and input parameters
;------------------------------------------------------
print_aligned	proc	 s:word, s_end:word
	push	bp
	mov	bp, sp

	mov	bx, V_STARTPOS				; begin with V_STARTPOS line, bp - vertical position
	mov	si, s

	mov	di, si					;	\-\-\-\-\-\-\-\-\-\-\
	mov	dx, si					;	 \       \       \
							;	 si      dx      di
							;	start  old new   finding new

	dec	dx					; print_line starts with inc	dx (podgon...)

@@print_line:						; external loop	that prints line by line
	inc	dx					; skip separation space
	mov	si, dx					; start with 'old new' position

	@@max_seq:					; loop	that find max sequence that fits in the line
		mov	dx, di

		cmp	byte ptr [di], 0
		je	@@terminate_print

		@@find_space:
			inc	di

			cmp	byte ptr [di], 0
			je	@@end_reached		; check for 'null' or space
			cmp	byte ptr [di], ' '
		jne	@@find_space

		@@end_reached:
		mov	ax, di
		sub	ax, si
		cmp	al, box_width			; is it fit in the box?
	jbe	@@max_seq				; yes: continue searching

@@terminate_print:					; if end reached, print	last string

	mov	ax, dx
	sub	ax, si					; now, ax = len

	push	dx di ax				; save positions

	mov	cl, al
	mov	ax, bx					; set es:[di] to print	centering
	mov	ch, al
	call	set_center
	
	pop	cx					; restore length
	call	strncpy					; copy current line to vram
	inc	bx					; vertical position ++

	pop	di dx					; restore pointers

	cmp	si, s_end
jne	@@print_line

	pop	bp
	ret
print_aligned	endp


;------------------------------------------------------
;-----------------STRNCPY       FUNCTION---------------
; copy n bytes from 
;-------------------EXPECTED---------------------------
; cx - strlen
; si - source string
; es:[di] - address for copy to
;-------------------RETURNS----------------------------
; si/di - end of the copied/writed string
;-------------------DESTROYS---------------------------
; ax, cx, df
;------------------------------------------------------
strncpy	proc	
	mov	ah, clr_attr
	
	test cx, cx
	jz	@@strncpy_exit			; length = 0 => exit

	cld
	@@cpy_loop:
		lodsb
		stosw				; copy to es:[di]
	loop	@@cpy_loop

	@@strncpy_exit:
	ret
strncpy	endp




;atoi	proc	
;	cld
;	mov	bx, 10d
;	@@atoi_loop:
;		lodsb
;		sub	al, '0'
;		mov	bl, al
;		mul	10d
;		mov	dx, ax
;		
;------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------
