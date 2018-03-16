; tiles are here
INCLUDE "Projects/PieInTheSky/Data/TestTiles.z80"

; map is here
INCLUDE "Projects/PieInTheSky/Data/TestMap.z80"

InitLevel::
	; load the tiles
	ld		bc, TileLabel
	call	LoadTiles
	
	ld		de, TestMap
	; load the background map
	call	LoadMapToBkg

	; init the palettes
	call	InitPalettes
	
;	ldh		a, [SCROLL_BKG_X]		; scroll the background horiz one bit
;	add		5
;	ldh		[SCROLL_BKG_X], a
	
	ret

;----------------------------------------------------
; load the tiles from ROM into the tile video memory
;
; IN:	bc = address of tile data to load
;----------------------------------------------------
LoadTiles::
	ld		hl, TILES_MEM_LOC_1	; load the tiles to tiles bank 1

	ld		de, 17 * 16
	ld		d, $10  ; 16 bytes per tile
	ld		e, $10  ; number of tiles to load

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
	jp		nz, .load_tiles_loop
	dec		e
	jp		nz, .load_tiles_loop

	ret

;----------------------------------------------------
; load the tile map to the background
;
; IN:	bc = address of map to load
;----------------------------------------------------
LoadMapToBkg::
	ld		hl, MAP_MEM_LOC_0	; load the map to map bank 0

	ld 		c, %11111111
	
	ld 		a, 0
	ld		b, a
	ld		[CurrentMapColumnPos], a
	ld 		[CurrentBGMapScrollTileX], a
	
.load_map_loop
	ld  	a,[de]
	ld  	[hl],a
	
	inc 	de
	
	ld		a, c
	ld 		bc, %00100000
	add 	hl, bc
	ld		c, a
	
	ld		a, [CurrentMapColumnPos]
	inc		a
	ld		[CurrentMapColumnPos], a
	cp		%00100000
	jr  	nz,.go_to_map_loop
	
	ld 		a, 0
	ld		[CurrentMapColumnPos], a
	
	ld		a, [CurrentBGMapScrollTileX]
	inc		a
	ld		[CurrentBGMapScrollTileX], a
	
	ld		b, c
	ld		hl, MAP_MEM_LOC_0
	ld		a, [CurrentBGMapScrollTileX]
	ld 		c, a
	ld 		a, b
	ld		b, 0
	add		hl, bc
	ld		c, a
	
.go_to_map_loop
	dec 	bc
	ld  	a,b
	or  	c
	jr  	nz,.load_map_loop
	
.load_next_map_block
	ld 		c, %11111111
	ld 		a, 0
	ld		b, a
	
	ld		a, [CurrentMapBlock]
	inc		a
	ld		[CurrentMapBlock], a
	cp		%00000100
	jr  	nz,.load_map_loop
	
	ld		a, [CurrentMapBlock]
	dec		a
	ld		[CurrentMapBlock], a
	
	ld		a, 2
	ld		[CurrentBGMapScrollTileX], a
	
	ret

;----------------------------------------------------
; init the palettes to basic
;----------------------------------------------------
InitPalettes::
	ld		a, %10010011	; set palette colors

	; load it to all the palettes
	ldh		[PALETTE_BKG], a
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
	and		%00000111
	jr		nz, .return_to_main
	
	ld		a, [CurrentMapBlock]
	ld		c, a
	ld		a,	TestMapBlockTotal
	cp		c
	jr		z, .return_to_main
	
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
	ld		c, %00100000
	ld		a, [TotalTilesScrolled]
	
.get_map_start_loop
	cp		0
	jr 		z, .get_map_block_loop_start
	add		hl, bc
	dec		a
	jr		.get_map_start_loop
	
.get_map_block_loop_start
	ld		bc, %100000000
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
	ld		a, [hl]
	ld		[de], a
	
	;Check if enemy sprite
	cp		14
	jr		c, .get_next_column_tile
	
	ld		a, 11
	ld		[de], a
	ld		a, c
	ld		[CurrentColumnHeight], a
	call CreateEnemy
	
.get_next_column_tile
	inc 	hl
	
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