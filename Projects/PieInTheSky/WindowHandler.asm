; bc contains window tiles address
LoadWindowTiles::
	ld		d, $10  ; 16 bytes per tile
	ld		e, 29  ; number of tiles to load

.load_tiles_loop
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .load_tiles_loop

	ld		a, [bc]		; get the next value from the source
	ld		[hli], a	; load the value to the destination, incrementing dest. ptr
	inc		bc			; increment the source ptr

	; now loop de times
	dec		d
	jr		nz, .load_tiles_loop
	ld		d, $10  ; 16 bytes per tile
	dec		e
	jr		nz, .load_tiles_loop
	
	ret
	
LoadMapToWindow::
	ld		hl, MAP_MEM_LOC_1
	ld		de, WindowMap
	ld		a, 20
	ld		b, a
	ld		a, [CurrentTilesetWidth]
	ld		c, a
	
.display_tiles_loop
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_tiles_loop
	
	ld		a, [de]
	add		c
	ld		[hli], a
	
	inc 	de
	dec		b
	jr		nz, .display_tiles_loop
	
	ret

; hl points at score start map address
; b holds the amount the player just scored
UpdateScoreDisplay::
	push 	de
	
	ld		d, 0
	ld		e, 6
	
	ld		a, b
	cp		0
	jr		z, .end_display_routine
	
	ld		c, 1
	cp		10
	jr		c, .offset_found
	dec		e
	ld		c, 10
	cp		100
	jr		c, .offset_found
	dec		e
	ld		c, 100
	
.offset_found
	add		hl, de
	
	; hl = current window address, b = amount scored, c = score decrement
.increase_next_score_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .increase_next_score_loop
	; get current tile index
	ld		a, [CurrentTilesetWidth]
	ld		e, a
	ld		a, [hl]
	dec		a
	dec		a
	sub		e
	ld		d, a
	
.increase_current_score_loop
	; increment tile index (increase number)
	inc		d
	ld		a, d
	cp		10
	; check if tile index is above 9
	; if not, take c away from current score and loop
	jr		nz, .subtract_c
	; if so, reset index to 0 and increment number to left of this. 
	; Repeat this check and consequence on that number
	ld		a, [CurrentTilesetWidth]
	ld		d, a
	
	ld		e, 1
.incrementing_to_left_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .incrementing_to_left_loop
	
	dec		hl
	ld		a, [hl]
	dec		a
	sub		d
	cp		10
	jr		nz, .finished_incrementing_to_left
.wait_for_sprite_mode_end_1
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_sprite_mode_end_1
	ld		a, 0
	inc		a
	inc 	a
	add		d
	ld		[hl], a
	inc		e
	jr		.incrementing_to_left_loop
	
.finished_incrementing_to_left
	inc		a
	inc 	a
	add		d
	ld		[hl], a
	
	ld		a, d
	ld		d, 0
	add 	hl, de
	
; take c away from current score
.subtract_c
	ld		a, b
	sub 	c
	ld		b, a
	cp		c
	jr		nc, .increase_current_score_loop
	jr		z, .increase_current_score_loop
	; if there is a carry flag, move down to c / 10 and index to right
	; if there is a carry flag and c = 1 then the score has been added
	ld		a, [CurrentTilesetWidth]
	ld		e, a
.wait_for_sprite_mode_end_2
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_sprite_mode_end_2
	
	ld		a, d
	inc		a
	inc 	a
	add		e
	ld		[hl], a
	inc		hl
	; if score left is zero then end routine
	ld		a, b
	cp		0
	jr		z, .end_display_routine
	
	ld		a, c
	cp		1
	jr		z, .end_display_routine
	cp		10
	jr		z, .loop_with_1
	
.loop_with_10
	ld		c, 10
	jr		.increase_next_score_loop
.loop_with_1
	ld		c, 1
	jr		.increase_next_score_loop
	
.end_display_routine
	pop 	de
	ret
	
DisplayMaxScore::
	ld		hl, MAP_MEM_LOC_1
	inc 	hl
	inc 	hl
	
	ld		a, [CurrentTilesetWidth]
	add 	11
	ld		b, a
	
	ld		c, 6
	
.max_score_display_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .max_score_display_loop
	
	ld		a, b
	ld		[hli], a
	
	dec		c
	jr 		nz, .max_score_display_loop
	
	ret

DisplayMinScore::
	ld		hl, MAP_MEM_LOC_1
	inc 	hl
	inc 	hl
	
	ld		a, [CurrentTilesetWidth]
	add 	2
	ld		b, a
	
	ld		c, 6
	
.min_score_display_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .min_score_display_loop
	
	ld		a, b
	ld		[hli], a
	
	dec		c
	jr 		nz, .min_score_display_loop
	
	ret
	
UpdateLivesDisplay::
	ld		hl, MAP_MEM_LOC_1
	ld		b, 0
	ld		c, 19
	add		hl, bc
	
	ld		a, [CurrentTilesetWidth]
	add 	2
	ld		b, a
.wait_for_sprite_mode_end
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_sprite_mode_end
	
	ld		a, [lives]
	add		b
	
	ld		[hl], a
	
	ret