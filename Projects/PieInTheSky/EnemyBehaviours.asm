; Enemy behaviour data
; Data setup:
; column 0: tile no
; column 1: health
; column 2: tile width
; column 3: tile height
; column 4: animation data address
; column 5: score value
; column 6: misc
; column 7: misc
; column 8: misc 
; column 9: misc (use to store anything needed)

;------------------------------------------------------
; update enemy behaviour
; hl = data address of enemy
; put hl back as it was once finished with it
;------------------------------------------------------
PatternEnemyUpdate::
	ld		b, 0
	ld		c, 8
	add		hl, bc
	
	ld		a, [hli]
	and		%00001111
	cp 		0
	jr 		z, .check_x_update
	
	ld		b, a
	ld		a, [hl]
	and		%00001111
	cp		b
	ld		b, a
	jr  	nz, .update_y_timer
	
	dec 	hl
	dec 	hl
	dec 	hl
	call 	UpdatePatternPosition
	inc 	hl
	inc 	hl
	inc 	hl
	
	jr		.reset_y_timer
	
.update_y_timer
	cp		15
	jr		z, .reset_y_timer
	inc		b
	jr		.check_x_update
.reset_y_timer
	ld		b, 0
	
.check_x_update
	ld		c, 0
	dec		hl
	ld		a, [hli]
	swap 	a
	and		%00001111
	cp 		0
	jr 		z, .end_update
	
	ld		c, a
	ld		a, [hl]
	swap 	a
	and		%00001111
	cp		c
	ld		c, a
	jr  	nz, .update_x_timer
	
	dec 	hl
	dec 	hl
	inc 	de
	call 	UpdatePatternPosition
	dec 	de
	inc 	hl
	inc 	hl
	
	jr 		.reset_x_timer
	
.update_x_timer
	cp		15
	jr		z, .reset_x_timer
	inc		c
	jr		.end_update
.reset_x_timer
	ld		c, 0
	
.end_update
	swap 	c
	ld		a, c
	add 	a, b
	ld		[hl], a
	
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	dec 	hl
	ret
	
UpdatePatternPosition::
	push 	bc
	
	ld		a, [hl]
	ld		b, a
	ld		a, [de]
	bit		0, b
	jr		z, .decrement
	
	inc		a
	jr		.pos_updated
.decrement
	dec 	a
.pos_updated
	ld		[de], a
	
	ld		a, b
	and		%11111110
	srl 	a
	cp 		0
	jr		z, .end_update
	
	dec 	a
	ld		c, a
	sla 	a
	ld		b, a
	
	ld		a, [hl]
	and		%00000001
	add 	a, b
	ld		[hl], a
	
	ld		a, c
	cp		0
	jr		nz, .end_update
	
	ld		a, [hl]
	bit		0, a
	jr		z, .set_bit
	
	res		0, a
	jr		.save_bit_change
.set_bit
	set		0, a
.save_bit_change
	ld		[hl], a
	
.end_update
	pop		bc
	ret
	
Enemy1Update::
	ld		a, [de]
	dec		a
	ld		[de], a
	
	ret