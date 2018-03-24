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
	
	ld		a, 64
	ld		[spaceshipGun_ypos], a
	add		a, 15
	ld		[spaceshipGun_xpos], a
	ld		a, 13
	ld		[spaceshipGun_tile], a
	ld		a, 0
	ld		[spaceshipGun_flags], a
	
	ld		a, 0
	ld		[spaceshipGunVertical_ypos], a
	ld		[spaceshipGunVertical_xpos], a
	ld		a, 14
	ld		[spaceshipGunVertical_tile], a
	ld		a, 0
	ld		[spaceshipGunVertical_flags], a
	
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
	
	ld		a, [current_bullet_direction]
	cp		1
	jr		z, .store_vertical_gun_addr
	cp		3
	jr		z, .store_vertical_gun_addr
	
	ld		de, spaceshipGun_xpos
	jp		.scroll_gun_left
	
.store_vertical_gun_addr
	ld		de, spaceshipGunVertical_xpos

.scroll_gun_left
	ld		a, [de]
	dec		a
	ld		[de], a
	
.return_to_main
	ret
	
;-------------------------------------------------------------
; adjust my spaceship sprite based on d-pad presses.  This
; both moves the sprite and chooses the sprite attributes to
; make the sprite face the correct direction
;-------------------------------------------------------------
MoveSpaceship::
	push	af
	
	; up was held down
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .done_checking_dpad
	
	call 	CheckDirectionInputs
	
.done_checking_dpad
	call 	ResolveShipEnemyCollisions
	
.check_for_b_press
	ld		a, [joypad_down]
	bit		B_BUTTON, a
	jp		z, .check_for_a_press
	
	call	ChangeBulletDirection

.check_for_a_press
	ld		a, [joypad_down]
	bit		A_BUTTON, a
	jp		z, .did_not_fire
	
	call	LaunchBullet
	
.did_not_fire
	pop		af
	ret	

;-------------------------------------------------------------
; check buttons for d-pad presses - de = current gun sprite
;-------------------------------------------------------------
CheckDirectionInputs::
	call StoreCurrentGunSpriteAddr
	
	ld		a, [joypad_held]
	bit		DPAD_UP, a
	jp		z, .check_for_down	; if button not pressed then done

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		16
	jp 		z, .check_for_left
	
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	ld		a, [de]
	dec		a
	ld		[de], a

	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	
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
	
	ld		a, [de]
	inc		a
	ld		[de], a
	
	; don't check down, since up + down should never occur
	jp		.check_for_left

.check_for_down
	ld		a, [joypad_held]
	bit		DPAD_DOWN, a
	jp		z, .check_for_left	; if button not pressed then done

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	ld		a, [de]
	inc		a
	ld		[de], a
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	
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
	
	ld		a, [de]
	dec		a
	ld		[de], a
	
.check_for_left
	inc 	de
	
	ld		a, [joypad_held]
	bit		DPAD_LEFT, a
	jp		z, .check_for_right	; if button not pressed then done

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		8
	jp 		z, .done_checking_dpad
	
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	ld		a, [de]
	dec		a
	ld		[de], a
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	inc		de
	
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
	
	ld		a, [de]
	inc		a
	ld		[de], a
	
	jp		.done_checking_dpad	; if left was pressed, don't check right

.check_for_right
	ld		a, [joypad_held]
	bit		DPAD_RIGHT, a
	jp		z, .done_checking_dpad	; if button not pressed then done

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	ld		a, [de]
	inc		a
	ld		[de], a
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	inc 	de
	
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
	
	ld		a, [de]
	dec		a
	ld		[de], a
	
.done_checking_dpad
	ret
	
;-----------------------------------------------------------------
; Find tile index of 
; B = xBottomLeftShipTileIndex, C = yBottomLeftShipTileIndex
;-----------------------------------------------------------------
FindShipTileIndexes::
	ld		a, [PixelsScrolled]
	ld		b, a
	ld 		a, [spaceshipL_xpos]
	sub		9
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

;-----------------------------------------------------------------
; Returns current gun sprite address in de
;-----------------------------------------------------------------
StoreCurrentGunSpriteAddr::
	ld		a, [current_bullet_direction]
	cp		1
	jr		z, .store_vertical_gun_addr
	cp		3
	jr		z, .store_vertical_gun_addr
	
	ld		de, spaceshipGun_ypos
	jp		.found_address
	
.store_vertical_gun_addr
	ld		de, spaceshipGunVertical_ypos
	
.found_address
	ret
	
	
ResolveShipEnemyCollisions::
	ld		hl, enemy_data
	ld		b, 6		; 6 enemies to update
.check_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .check_enemy_pos_loop_end

	; this is an active enemy
	; get its sprite addr
	push	hl
	ld		a, 6	; calc index (16 - b)
	sub		b
	ld		e, a	; store index in de
	sla		e
	sla		e		; 4 bytes per sprite attrib
	ld		d, 0
	ld		hl, enemy_sprites
	add		hl, de
	ld		d, h
	ld		e, l	; store the address in de
	pop		hl
	
.check_y
	ld		a, [de]
	ld		c, a
	ld		a, [spaceshipL_ypos]
	add		8
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	inc 	hl
	inc 	hl
	inc 	hl
	ld		a, [hl]
	dec 	hl
	dec 	hl
	dec 	hl
	ld		c, a
	ld		a, 0
	
.enemy_height_loop_start
	add		8
	dec		c
	jr		nz, .enemy_height_loop_start
	
	ld		c, a
	ld		a, [de]
	add		c
	ld		c, a
	ld		a, [spaceshipL_ypos]
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		nc, .check_enemy_pos_loop_end
	
.check_x
	inc 	de
	ld		a, [de]
	ld		c, a
	ld		a, [spaceshipR_xpos]
	add		8
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	inc 	hl
	inc 	hl
	ld		a, [hl]
	dec 	hl
	dec 	hl
	ld		c, a
	ld		a, 0
	
.enemy_width_loop_start
	add		8
	dec		c
	jr		nz, .enemy_width_loop_start
	
	ld		c, a
	ld		a, [de]
	add		c
	ld		c, a
	ld		a, [spaceshipL_xpos]
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		nc, .check_enemy_pos_loop_end
	
	;damage or destroy ship
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
.check_enemy_pos_loop_end
	inc		hl
	inc		hl
	inc		hl
	inc		hl
	dec		b
	jp		nz, .check_enemies_pos_loop
	
	ret