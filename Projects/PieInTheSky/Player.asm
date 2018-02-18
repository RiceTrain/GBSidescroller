InitPlayerSprite::
	; init  my spaceship sprite
	ld		a, $40
	ld		[spaceshipL_xpos], a
	ld		[spaceshipL_ypos], a
	ld		a, 9
	ld		[spaceshipL_tile], a
	ld		a, 0
	ld		[spaceshipL_flags], a
	
	ld		a, $40
	ld		[spaceshipR_ypos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	ld		a, 10
	ld		[spaceshipR_tile], a
	ld		a, 0
	ld		[spaceshipR_flags], a
	
	ret

ResolvePlayerScrollCollisions::
	call FindShipTileIndexes
	
	inc 	hl
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .return_to_main
	
.MoveShipBackLeft
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
.return_to_main
	ret
	
;-------------------------------------------------------------
; adjust my spaceship sprite based on d-pad presses.  This
; both moves the sprite and chooses the sprite attributes to
; make the sprite face the correct direction
;-------------------------------------------------------------
MoveSpaceship::
	push	af
	
	; check buttons for d-pad presses
.check_for_up
	ld		a, [joypad_held]
	bit		DPAD_UP, a
	jp		z, .check_for_down	; if button not pressed then done

	; up was held down
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .check_for_left

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		16
	jp 		z, .check_for_left
	
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a

	call FindShipTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackDown

	inc		hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackDown

	inc		hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .check_for_left
	
.MoveShipBackDown
	ld		a, [spaceshipL_ypos]
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	; don't check down, since up + down should never occur
	jp		.check_for_left

.check_for_down
	ld		a, [joypad_held]
	bit		DPAD_DOWN, a
	jp		z, .check_for_left	; if button not pressed then done

	; down was held down
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .check_for_left

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	call FindShipTileIndexes
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .check_for_left
	
.MoveShipBackUp
	ld		a, [spaceshipL_ypos]
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
.check_for_left
	ld		a, [joypad_held]
	bit		DPAD_LEFT, a
	jp		z, .check_for_right	; if button not pressed then done

	; left was pressed
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .done_checking_dpad

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		8
	jp 		z, .done_checking_dpad
	
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	call FindShipTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackRight
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .done_checking_dpad
	
.MoveShipBackRight
	ld		a, [spaceshipL_xpos]
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
	jp		.done_checking_dpad	; if left was pressed, don't check right

.check_for_right
	ld		a, [joypad_held]
	bit		DPAD_RIGHT, a
	jp		z, .done_checking_dpad	; if button not pressed then done

	; right was pressed
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .done_checking_dpad

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	call FindShipTileIndexes
	
	inc 	hl
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .done_checking_dpad
	
.MoveShipBackLeft
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
.done_checking_dpad
	ld		a, [joypad_down]
	bit		A_BUTTON, a
	jp		z, .check_for_bomb
	
	call	LaunchBullet
	
.check_for_bomb
	ld		a, [joypad_down]
	bit		B_BUTTON, a
	jp		z, .did_not_fire
	
	call	LaunchBomb

.did_not_fire
	pop		af
	ret	

;-----------------------------------------------------------------
; Find tile index of 
; B = xBottomLeftShipTileIndex, C = yBottomLeftShipTileIndex
;-----------------------------------------------------------------
FindShipTileIndexes::
	ld		a, [PixelsScrolled]
	ld		b, a
	ld 		a, [spaceshipL_xpos]
	sub		4
	add		a, b
	ld		b, -1
	
.XSubLoop
	jr		c, .StartYLoop
	sub		8
	inc 	b
	jp		.XSubLoop

.StartYLoop
	ld 		a, [spaceshipL_ypos]
	sub		8
	ld		c, -2
	
.YSubLoop
	jr		c, .EndTileIndexLoops
	sub		8
	inc 	c
	jp		.YSubLoop
	
.EndTileIndexLoops
	ld		a, 0
	ld		h, a
	ld 		a, [CurrentWindowTileX]
	add		b
	
	cp		32
	jr		c, .StoreStartAndMapWidth
	
	sub 	32
	
.StoreStartAndMapWidth
	ld		l, a
	
	ld		a, 0
	ld		d, a
	ld		a, 32
	ld		e, a
	
	ld 		a, c
	
.GetTileIndexLoop
	add		hl, de
	dec		a
	jr		nz, .GetTileIndexLoop
	
	ld		d, h
	ld		e, l
	ld		hl, MAP_MEM_LOC_0
	add 	hl, de ;HL now contains the address of the tile at the bottom left ship co-ordinate
	
	ret