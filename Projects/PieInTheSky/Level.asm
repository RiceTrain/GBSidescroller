InitLevel::
	ld		a, $1a
	ld		[CurrentTilesetWidth], a
	
	; load the tiles
	ld		bc, TileLabel
	call	LoadTiles
	
	ld		bc, WindowTiles
	call	LoadWindowTiles
	
	; init the palettes
	call	InitPalettes
	
	ld		a, 0
	ld		[level_end_reached], a
	ld		a, 0
	ld		[boss_defeated], a
	
	ret

;----------------------------------------------------
; load the tiles from ROM into the tile video memory
;
; IN:	bc = address of tile data to load
;----------------------------------------------------
LoadTiles::
	ld		hl, TILES_MEM_LOC_1	; load the tiles to tiles bank 1

	ld		d, $10  ; 16 bytes per tile
	ld 		a, [CurrentTilesetWidth] ; number of tiles to load
	ld		e, a

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

;------------------------------------------
; init the local copy of the sprites
;------------------------------------------
InitSprites::
	ld		hl, $c000	; my sprites are at $c000
	ld		b, 40*4		; 40 sprites, 4 bytes per sprite
	ld		a, 0
.init_sprites_loop
	ld		[hli], a
	dec		b
	jr		nz, .init_sprites_loop
	
	ret

;----------------------------------------------------
; load the tile map to the background
;
; IN:	hl = address of map to load
;----------------------------------------------------
LoadMapToBkg::
	ld		b, 0
	ld		c, 18
	ld		a, [checkpoint_tiles_scrolled]
	
.get_map_start_loop
	cp		0
	jr 		z, .get_map_block_loop_start
	add		hl, bc
	dec		a
	jr		.get_map_start_loop
	
.get_map_block_loop_start
	ld		bc, 144
	ld		a, [checkpoint_map_block]
	
.get_map_block_loop
	cp		0
	jr 		z, .setup_load_map_loop
	add		hl, bc
	dec		a
	jr		.get_map_block_loop
	
.setup_load_map_loop
	ld		a, 0
	ld		[CurrentMapBlock], a
	
	ld		d, h
	ld		e, l
	ld		hl, MAP_MEM_LOC_0	; load the map to map bank 0

	ld 		c, 255
	
	ld 		a, 0
	ld		b, a
	ld 		[CurrentBGMapScrollTileX], a
	
.load_map_loop
	ld		a, h
	cp		$9a
	jr		c, .load_tile
	jr		nz, .load_zero
	
	ld		a, l
	cp		$40
	jr		c, .load_tile

.load_zero
	ld		b, 0
	jr		.wait_for_write_mode
	
.load_tile
	ld  	a, [de]
	ld		b, a
	inc 	de
	
.wait_for_write_mode
	call 	Wait_For_Vram
	
.load_into_map_mem
	ld		a, b
	ld  	[hl],a
	
	ld		a, c
	ld 		bc, %00100000
	add 	hl, bc
	ld		c, a
	
	ld		a, h
	dec		a
	cp		$9b
	jr		c, .go_to_map_loop
	
	ld		a, [CurrentBGMapScrollTileX]
	inc		a
	ld		[CurrentBGMapScrollTileX], a
	
	ld		a, h
	sub		4
	ld		h, a
	
	ld		a, l
	inc 	a
	ld		l, a
	
.go_to_map_loop
	dec 	bc
	ld  	a,b
	or  	c
	jr  	nz,.load_map_loop
	
.load_next_map_block
	ld 		c, 255
	ld 		a, 0
	ld		b, a
	
	ld		a, [CurrentMapBlock]
	inc		a
	ld		[CurrentMapBlock], a
	cp		%00000100
	jr  	nz,.load_map_loop

	ld		a, [checkpoint_tiles_scrolled]
	ld		[TotalTilesScrolled], a
	ld		a, [checkpoint_map_block]
	add		3
	ld		[CurrentMapBlock], a
	
	ld		a, 2
	ld		[CurrentBGMapScrollTileX], a
	
	ret

;----------------------------------------------------
; init the palettes to basic
;----------------------------------------------------
InitPalettes::
	ld		a, %10011100	; set palette colors
	ldh		[PALETTE_BKG], a
	ld		a, %10010011	; set palette colors
	ldh		[PALETTE_SPRITE_0], a
	ldh		[PALETTE_SPRITE_1], a

	ret

;----------------------------------------------------
; Scroll the level
;----------------------------------------------------
ScrollLevel::
	; increment my little timer
	ld		a, [ScrollTimer]			; get the scroll timer
	inc		a					; increment it
	ld		[ScrollTimer], a
	
	; is it time to scroll yet?
	and		%00000110
	jr		nz, .return_to_main
	
	ld		a, [CurrentMapBlock]
	ld		c, a
	ld		a,	[CurrentMapBlockTotal]
	cp		c
	jr		nz, .continue_scrolling
	
	ld		a, [level_end_reached]
	cp		1
	jr		z, .return_to_main
	
	ld		a, 1
	ld		[level_end_reached], a
	
	ld		a, [boss_defeated]
	cp		0
	jr		z, .return_to_main
	
	call	DisplayLevelEndStats
	
	jr		.return_to_main
	
.continue_scrolling
	ld 		a, [PixelsScrolled]
	inc 	a
	ld 		[PixelsScrolled], a
	
	and		%00000111				;increment tiles scrolled every 8 pixels
	jr		nz, .vblank_do_scroll
	
	call HandleColumnLoad

.vblank_do_scroll
	; do a background screen scroll
	ldh		a, [SCROLL_BKG_X]		; scroll the background horiz one bit
	inc		a
	ldh		[SCROLL_BKG_X], a
	
	call UpdateEnemyScrollPositions
	call ResolvePlayerScrollCollisions

.process_checkpoint
	ld		a, [checkpoint_pixels]
	cp		$ff
	jr		z, .return_to_main
	
	dec		a
	ld		[checkpoint_pixels], a
	cp		0
	jr		nz, .return_to_main
	
	ld		a, [checkpoint_appearance_map_block]
	ld		[checkpoint_map_block], a
	ld		a, [checkpoint_appearance_tiles_scrolled]
	ld		[checkpoint_tiles_scrolled], a
	ld		a, [checkpoint_appearance_ship_y]
	ld		[checkpoint_ship_y], a
	
	ld		a, $ff
	ld		[checkpoint_pixels], a
	
.return_to_main
	ret
	
;---------------------------------------------------
; Handle screen scroll and load here
;---------------------------------------------------
HandleColumnLoad::
	ld 		a, 0
	ld 		[PixelsScrolled], a
	
	ld 		a, [TotalTilesScrolled]
	inc 	a
	ld 		[TotalTilesScrolled], a
	
	cp		%00001000	;reset count if a = 8
	jr		nz, .track_screen_scroll
	
	ld		a, [CurrentMapBlock]
	inc 	a
	ld		[CurrentMapBlock], a
	
	ld 		a, 0
	ld 		[TotalTilesScrolled], a
	
.track_screen_scroll
	ld 		a, [CurrentBGMapScrollTileX]
	inc 	a
	ld 		[CurrentBGMapScrollTileX], a
	
	cp		%00001010	;reset count if a = 10 = -22 + 32
	jr		nz, .track_window_scroll
	
	ld 		a, 0
	sub 	%00010110 ;22
	ld 		[CurrentBGMapScrollTileX], a

.track_window_scroll
	ld 		a, [CurrentWindowTileX]
	inc 	a
	ld 		[CurrentWindowTileX], a
	
	cp		%00100000	;reset count if a = 32
	jr		nz, .get_map_start_point
	
	ld 		a, 0
	ld 		[CurrentWindowTileX], a
	
.get_map_start_point
	ld		hl, TestMap	; load the map to map bank 0
	
	ld		b, 0
	ld		c, 18
	ld		a, [TotalTilesScrolled]
	
.get_map_start_loop
	cp		0
	jr 		z, .get_map_block_loop_start
	add		hl, bc
	dec		a
	jr		.get_map_start_loop
	
.get_map_block_loop_start
	ld		bc, 144
	ld		a, [CurrentMapBlock]
	
.get_map_block_loop
	cp		0
	jr 		z, .load_next_map_column
	add		hl, bc
	dec		a
	jr		.get_map_block_loop
	
.load_next_map_column
	ld		de, MAP_MEM_LOC_0
	ld 		a, [CurrentBGMapScrollTileX]
	add		a, %00010110 ;22
	ld		c, a
	ld		a, e
	add		a, c
	ld		e, a
	
	ld 		c, %00100000
	
.load_next_column_loop
	ld		a, d
	cp		$9a
	jr		c, .load_tile
	jr		nz, .load_zero
	
	ld		a, e
	cp		$40
	jr		c, .load_tile

.load_zero
	ld		b, 0
	jr		.wait_for_write_mode
	
.load_tile
	ld		a, [hl]
	ld		b, a
	inc 	hl
	
.wait_for_write_mode
	call Wait_For_Vram
	
.load_into_map_mem
	ld		a, b
	ld		[de], a
	
	cp		10
	jr		nz, .check_for_enemy_tile
	
.checkpoint_found
	ld		a, 116
	ld		[checkpoint_pixels], a
	ld		a, [CurrentMapBlock]
	dec		a
	ld		[checkpoint_appearance_map_block], a
	ld		a, [TotalTilesScrolled]
	ld		[checkpoint_appearance_tiles_scrolled], a
	
	ld		a, [current_score]
	ld		[checkpoint_current_score], a
	ld		a, [score_tracker_lower]
	ld		[checkpoint_score_tracker_lower], a
	ld		a, [score_tracker_higher]
	ld		[checkpoint_score_tracker_higher], a
	
	ld		a, c
	ld		b, a
	ld		a, 34
	sub		b
	ld		b, a
	ld		a, 0
	
.calculate_ship_y_loop
	add		a, 8
	dec		b
	jr		nz, .calculate_ship_y_loop
	
	ld		[checkpoint_appearance_ship_y], a
	
	jp		.get_next_column_tile

.check_for_enemy_tile
	call	CheckIfEnemyTile
	jr		nz, .get_next_column_tile
	
	ld		a, 0
	ld		[de], a
	ld		a, c
	ld		[CurrentColumnHeight], a
	dec 	hl
	call 	CreateEnemy
	inc		hl
	
.get_next_column_tile
	ld 		a, c
	
	ld		b, h
	ld		c, l
	ld		h, d
	ld		l, e 			;store hl -> bc, de -> hl
	ld		de, %00100000	
	add		hl, de			;add 32 to hl (current address of bg map)
	ld		d, h
	ld		e, l
	ld 		h, b
	ld 		l, c			;store hl -> de, bc -> hl
	
	ld		b, 0
	ld 		c, a
	
	dec		c
	ld		a, b
	or 		c
	jr		nz, .load_next_column_loop
	
	ret