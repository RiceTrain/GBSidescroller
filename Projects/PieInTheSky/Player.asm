InitPlayerData::
	ld		a, 1
	ld		[alive], a
	ld		a, 120
	ld		[death_timer], a
	ld		a, 5
	ld		[player_animation_timer], a
	ld		hl, spaceshipLAnim1_ypos
	ld		a, h
	ld		[current_anim_frame_upper], a
	ld		a, l
	ld		[current_anim_frame_lower], a
	
	ret
	
InitPlayerSprite::
	; init  my spaceship sprite
	ld		a, [checkpoint_ship_y]
	ld		[spaceshipL_ypos], a
	ld		a, 80
	ld		[spaceshipL_xpos], a
	ld		a, 14
	ld		[spaceshipL_tile], a
	ld		a, 0
	ld		[spaceshipL_flags], a
	
	ld		a, [checkpoint_ship_y]
	ld		[spaceshipR_ypos], a
	ld		a, 88
	ld		[spaceshipR_xpos], a
	ld		a, 15
	ld		[spaceshipR_tile], a
	ld		a, 0
	ld		[spaceshipR_flags], a
	
	ld		a, [checkpoint_ship_y]
	ld		[spaceshipLAnim1_ypos], a
	ld		a, 72
	ld		[spaceshipLAnim1_xpos], a
	ld		a, 16
	ld		[spaceshipLAnim1_tile], a
	ld		a, 0
	ld		[spaceshipLAnim1_flags], a
	
	ld		a, [checkpoint_ship_y]
	ld		[spaceshipGun_ypos], a
	ld		a, 95
	ld		[spaceshipGun_xpos], a
	ld		a, 12
	ld		[spaceshipGun_tile], a
	ld		a, 0
	ld		[spaceshipGun_flags], a
	
	ld		a, 0
	ld		[spaceshipGunVertical_ypos], a
	ld		[spaceshipGunVertical_xpos], a
	ld		a, 13
	ld		[spaceshipGunVertical_tile], a
	ld		a, 0
	ld		[spaceshipGunVertical_flags], a
	
	ld		a, 0
	ld		[spaceshipLAnim2_ypos], a
	ld		[spaceshipLAnim2_xpos], a
	ld		a, 17
	ld		[spaceshipLAnim2_tile], a
	ld		a, 0
	ld		[spaceshipLAnim2_flags], a
	
	ret

ResolvePlayerScrollCollisions::
	call FindShipTileIndexes
	
	inc 	hl
	inc 	hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		z, .return_to_main
	
.MoveShipBackLeft
	call 	StoreCurrentPlayerAnimAddress
	inc		hl
	
	call	Wait_For_Vram
	
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	sub		16
	ld		[hl], a
	
	ld		a, [current_bullet_direction]
	cp		1
	jr		z, .store_vertical_gun_addr
	cp		3
	jr		z, .store_vertical_gun_addr
	
	ld		de, spaceshipGun_xpos
	jr		.scroll_gun_left
	
.store_vertical_gun_addr
	ld		de, spaceshipGunVertical_xpos

.scroll_gun_left
	call	Wait_For_Vram
	
	ld		a, [de]
	dec		a
	ld		[de], a
	
	ld		a, [spaceshipL_xpos]
	cp 		9
	jp 		nc, .return_to_main
	
	call	DestroyShip
	
.return_to_main
	ret

;Gets the current frame's sprite address and stores in HL
StoreCurrentPlayerAnimAddress::
	ld		a, [current_anim_frame_upper]
	ld		h, a
	ld		a, [current_anim_frame_lower]
	ld		l, a
	
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
	
	ld		a, [alive]
	cp 		0
	jr		z, .did_not_fire
	
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

	call	Wait_For_Vram
	
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
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	ld		a, [spaceshipL_ypos]
	ld		[hl], a
	pop		hl
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackDown

	inc		hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackDown

	inc		hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jp		z, .check_for_left
	
.MoveShipBackDown
	call	Wait_For_Vram
	
	ld		a, [spaceshipL_ypos]
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	ld		a, [de]
	inc		a
	ld		[de], a
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	ld		a, [spaceshipL_ypos]
	ld		[hl], a
	pop		hl
	
	; don't check down, since up + down should never occur
	jp		.check_for_left

.check_for_down
	ld		a, [joypad_held]
	bit		DPAD_DOWN, a
	jp		z, .check_for_left	; if button not pressed then done

	call	Wait_For_Vram
	
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
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	ld		a, [spaceshipL_ypos]
	ld		[hl], a
	pop		hl
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		z, .check_for_left
	
.MoveShipBackUp
	call	Wait_For_Vram
	
	ld		a, [spaceshipL_ypos]
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	ld		a, [de]
	dec		a
	ld		[de], a
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	ld		a, [spaceshipL_ypos]
	ld		[hl], a
	pop		hl
	
.check_for_left
	inc 	de
	
	ld		a, [joypad_held]
	bit		DPAD_LEFT, a
	jp		z, .check_for_right	; if button not pressed then done

	call	Wait_For_Vram
	
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
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	inc		hl
	ld		a, [spaceshipL_xpos]
	sub		8
	ld		[hl], a
	pop		hl
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	inc		de
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackRight
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jp		z, .done_checking_dpad
	
.MoveShipBackRight
	call	Wait_For_Vram
	
	ld		a, [spaceshipL_xpos]
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
	ld		a, [de]
	inc		a
	ld		[de], a
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	inc		hl
	ld		a, [spaceshipL_xpos]
	sub		8
	ld		[hl], a
	pop		hl
	
	jp		.done_checking_dpad	; if left was pressed, don't check right

.check_for_right
	ld		a, [joypad_held]
	bit		DPAD_RIGHT, a
	jp		z, .done_checking_dpad	; if button not pressed then done

	call	Wait_For_Vram
	
	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		152
	jp 		z, .done_checking_dpad
	
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	ld		a, [de]
	inc		a
	ld		[de], a
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	inc		hl
	ld		a, [spaceshipL_xpos]
	sub		8
	ld		[hl], a
	pop		hl
	
	call 	FindShipTileIndexes
	call 	StoreCurrentGunSpriteAddr
	inc 	de
	
	inc 	hl
	inc 	hl
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	call	Wait_For_Vram
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		z, .done_checking_dpad
	
.MoveShipBackLeft
	call	Wait_For_Vram
	
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
	ld		a, [de]
	dec		a
	ld		[de], a
	
	push	hl
	call 	StoreCurrentPlayerAnimAddress
	inc		hl
	ld		a, [spaceshipL_xpos]
	sub		8
	ld		[hl], a
	pop		hl
	
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
	ld		b, 16		; 6 enemies to update
.check_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .check_enemy_pos_loop_end

	push	bc
	call	GetSpriteAddress
	pop		bc
	
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
	
	call	DestroyShip
	
	jp		.end_enemy_checking
	
.check_enemy_pos_loop_end
	push 	de
	ld		d, 0
	ld		a, [enemy_data_size]
	ld		e, a
	add		hl, de
	pop		de
	
	dec		b
	jp		nz, .check_enemies_pos_loop

.end_enemy_checking
	ret
	
DestroyShip::
	;destroy ship
	ld		a, 0
	ld		[spaceshipR_ypos], a
	ld		[spaceshipR_xpos], a
	ld		[spaceshipGun_ypos], a
	ld		[spaceshipGun_xpos], a
	ld		[spaceshipGunVertical_ypos], a
	ld		[spaceshipGunVertical_xpos], a
	ld		[spaceshipLAnim1_ypos], a
	ld		[spaceshipLAnim1_xpos], a
	ld		[spaceshipLAnim2_ypos], a
	ld		[spaceshipLAnim2_xpos], a
	
	ld		[alive], a
	
	ld		a, 20
	ld		[spaceshipL_tile], a ;use sprite for explosion
	
	ret
	
AnimateShip::
	ld		a, [player_animation_timer]
	dec		a
	ld		[player_animation_timer], a
	cp		0
	jr		nz, .anim_end
	
	ld		bc, spaceshipLAnim1_ypos
	ld		de, spaceshipLAnim2_ypos
	ld		a, [current_anim_frame_lower]
	cp		c
	jr		nz, .save_anim_address
	
	ld		bc, spaceshipLAnim2_ypos
	ld		de, spaceshipLAnim1_ypos
	
.save_anim_address
	ld		a, b
	ld		[current_anim_frame_upper], a
	ld		a, c
	ld		[current_anim_frame_lower], a
	
	ld		a, [de]
	ld		[bc], a
	inc		de
	inc		bc
	ld		a, [de]
	ld		[bc], a
	
	ld		a, 0
	ld		[de], a
	dec		de
	ld		[de], a
	
.reset_timer
	ld		a, 5
	ld		[player_animation_timer], a
	
.anim_end
	ret