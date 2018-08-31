; bc contains window tiles address
LoadWindowTiles::
;	ld		de, 13 * 16
	ld		d, $10  ; 16 bytes per tile
	ld		e, $0d  ; number of tiles to load

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
	ld		a, 19
	ld		b, a
	
.display_tiles_loop
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_tiles_loop
	
	ld		a, [de]
	add		26
	ld		[hli], a
	
	inc 	de
	dec		b
	jr		nz, .display_tiles_loop
	
	ret