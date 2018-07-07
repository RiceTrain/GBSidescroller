InitBulletData::
	; init my bullet sprites
	ld		hl, bullet_data                
	ld		b, 4		; 4 bullets in table
.init_bullets_loop
	ld 		a, $ff
	ld		[hli], a
	inc		hl			; 2 bytes per bullet

	dec		b
	jr		nz, .init_bullets_loop
	
	ret

;------------------------------------------------------------
; change shooting direction
;------------------------------------------------------------
ChangeBulletDirection::
	ld		a, [current_bullet_direction]
	inc 	a
	
	cp		4
	jr		nz, .direction_changed
	
	ld		a, 0
	
.direction_changed
	ld		[current_bullet_direction], a

.check_right
	cp		0
	jr		nz, .check_down

	ld		a, [spaceshipR_ypos]
	ld		[spaceshipGun_ypos], a
	
	ld		a, [spaceshipR_xpos]
	add		a, 7
	ld		[spaceshipGun_xpos], a
	
	ld		a, [spaceshipGun_flags]
	res 	5, a
	ld		[spaceshipGun_flags], a
	
	ld		a, 0
	ld		[spaceshipGunVertical_xpos], a
	ld		[spaceshipGunVertical_ypos], a
	
	jp		.directions_checked
	
.check_down
	cp		1
	jr		nz, .check_left
	
	ld		a, [spaceshipR_ypos]
	add		7
	ld		[spaceshipGunVertical_ypos], a
	
	ld		a, [spaceshipR_xpos]
	sub		4
	ld		[spaceshipGunVertical_xpos], a
	
	ld		a, [spaceshipGunVertical_flags]
	res 	6, a
	ld		[spaceshipGunVertical_flags], a
	
	ld		a, 0
	ld		[spaceshipGun_xpos], a
	ld		[spaceshipGun_ypos], a
	
	jp		.directions_checked

.check_left
	cp		2
	jr		nz, .check_up
	
	ld		a, [spaceshipR_ypos]
	ld		[spaceshipGun_ypos], a
	
	ld		a, [spaceshipR_xpos]
	sub		22
	ld		[spaceshipGun_xpos], a
	
	ld		a, [spaceshipGun_flags]
	set 	5, a
	ld		[spaceshipGun_flags], a
	
	ld		a, 0
	ld		[spaceshipGunVertical_xpos], a
	ld		[spaceshipGunVertical_ypos], a
	
	jp		.directions_checked

.check_up
	cp		3
	jr		nz, .directions_checked
	
	ld		a, [spaceshipR_ypos]
	sub		7
	ld		[spaceshipGunVertical_ypos], a
	
	ld		a, [spaceshipR_xpos]
	sub		4
	ld		[spaceshipGunVertical_xpos], a
	
	ld		a, [spaceshipGunVertical_flags]
	set 	6, a
	ld		[spaceshipGunVertical_flags], a
	
	ld		a, 0
	ld		[spaceshipGun_xpos], a
	ld		[spaceshipGun_ypos], a

.directions_checked
	ret
	
;------------------------------------------------------------
; launch a bullet
;------------------------------------------------------------
LaunchBullet::
	push	af
	push	bc
	push	de

	; find an empty bullet
	ld		hl, bullet_data		; get the addr of the 1st bullet
	ld		d, 4				; 4 bullet slots to check
.find_empty_bullet_loop
	ld		a, [hl]
	cp		$ff			; is this bullet unused
	jr		z, .found_empty_bullet

	inc		hl	; skip 2 bytes, to top of next bullet
	inc		hl

	dec		d
	jr		nz, .find_empty_bullet_loop

	; no slots left... exit
	pop		de
	pop		bc
	pop		af
	ret

.found_empty_bullet
	ld		a, [spaceshipR_xpos]
	sub		4
	ld		b, a
	ld		a, [current_bullet_direction]
	
	cp		0
	jr		nz, .check_for_left
	
	ld		a, b
	add     a, 12
	ld		b, a
	
.check_for_left
	cp		2
	jr		nz, .setup_y_pos
	
	ld		a, b
	sub     a, 20
	ld		b, a
	
.setup_y_pos
	; calc bullet y launch pos
	ld		a, [spaceshipR_ypos]
	ld		c, a
	ld		a, [current_bullet_direction]
	
	cp		1
	jr		nz, .check_for_up
	
	ld		a, c
	add     a, 8
	ld		c, a
	
.check_for_up
	cp		3
	jr		nz, .continue_setup
	
	ld		a, c
	sub     a, 8
	ld		c, a

.continue_setup
	; a = orientation
	; b = x pos
	; c = y pos
	; hl = bullet data to launch
	; index into bullet array = 16 - d

	ld		a, [current_bullet_direction]
	ld		[hli], a	; store the orientation
	ld		[hl], 90	; bullet lasts 1 second (60 vblanks)

	ld		a, 4
	sub		d		; a = index into bullet array

	ld		hl, bullet_sprites	; get top of bullet sprites

	sla		a
	sla		a		; multiply index by 4 (4 bytes per sprite)
	ld		e, a	; store it in de
	ld		d, 0

	add		hl, de	; I should be pointing at the correct sprite addr

	; load the sprite info
	ld		[hl], c
	inc		hl
	ld		[hl], b
	inc		hl
	ld		[hl], 11	; bullets use tile 12
	inc		hl
	ld		[hl], 0

	call	PlayBulletSound
	
	pop		de
	pop		bc
	pop		af
	ret
	
;-----------------------------------------------------------------
; update the bullet timing ever vblank
;-----------------------------------------------------------------
UpdateBulletTimers::
	push	af
	push	bc
	push	hl

	ld		hl, bullet_data
	ld		b, 4		; 4 bullets to update
.update_bullets_loop
	ld		a, [hli]
	cp		$ff
	jr		z, .update_bullets_loop_end

	; this is an active bullet
	dec		[hl]	; decrement the timer
	jr		nz, .update_bullets_loop_end

	; this bullet's timer ran out
	push	hl		; save where we were
	push	bc

	dec		hl		; go back a byte
	ld		a, $ff
	ld		[hl], a	; this sprite is no longer active

	; calc this bullet's sprite location
	ld		a, 4	; calc index (4 - b)
	sub		b
	ld		e, a	; store index in de
	sla		e
	sla		e		; 4 bytes per sprite attrib
	ld		d, 0
	ld		hl, bullet_sprites
	add		hl, de

	ld		a, $00
	ld		[hli], a
	ld		[hl], a		; turn of the sprite in the attrib table
	pop		bc
	pop		hl

.update_bullets_loop_end
	inc		hl
	dec		b
	jr		nz, .update_bullets_loop

	pop		hl
	pop		bc
	pop		af
	ret
	
;------------------------------------------------------
; update bullet positions
;------------------------------------------------------
UpdateBulletPositions::
	push	af
	push	bc

	ld		hl, bullet_data
	ld		b, 4		; 4 bullets to update
.update_bullets_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_bullets_pos_loop_end

	; this is an active bullet
	; get its sprite addr
	push	hl
	ld		a, 4	; calc index (16 - b)
	sub		b
	ld		e, a	; store index in de
	sla		e
	sla		e		; 4 bytes per sprite attrib
	ld		d, 0
	ld		hl, bullet_sprites
	add		hl, de
	ld		d, h
	ld		e, l	; store the address in de
	pop		hl

.bullet_fly
	; update this sprite's position
	ld		a, [de]
	ld		c, a
	ld		a, [hl]
.check_for_down
	cp		1
	jr		nz, .check_for_up
	
	ld		a, c
	add		2
	ld		c, a
	
.check_for_up
	cp		3
	jr		nz, .update_y_pos
	
	ld		a, c
	sub		2
	ld		c, a
	
.update_y_pos
	ld		a, c
	ld		[de], a
	ld		[current_bullet_ypos], a
	
	inc		de
	ld		a, [de]
	ld		c, a
	ld		a, [hl]
	
.check_for_right
	cp		0
	jr		nz, .check_for_left
	
	ld		a, c
	add		2
	ld		c, a
	
.check_for_left
	cp		2
	jr		nz, .update_x_pos
	
	ld		a, c
	sub		2
	ld		c, a
	
.update_x_pos
	ld		a, c
	ld		[de], a
	ld		[current_bullet_xpos], a
	dec		de
	
	push	hl
	push	bc
	push	de
	
	ld		a, [current_bullet_ypos]
	add		4
	ld		a, [current_bullet_xpos]
	add		4
	
	call FindBulletTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		0
	jr		nz, .destroy_bullet_on_collision_or_bounds
	
.check_screen_bounds
	ld		a, [current_bullet_ypos]
	cp		160
	jr		z, .destroy_bullet_on_collision_or_bounds
	jr		nc, .destroy_bullet_on_collision_or_bounds
	
	add		a, 8
	cp		8
	jr		z, .destroy_bullet_on_collision_or_bounds
	jr		c, .destroy_bullet_on_collision_or_bounds
	
	ld		a, [current_bullet_xpos]
	cp		168
	jr		z, .destroy_bullet_on_collision_or_bounds
	jr		nc, .destroy_bullet_on_collision_or_bounds
	
	add		a, 8
	cp		8
	jr		z, .destroy_bullet_on_collision_or_bounds
	jr		c, .destroy_bullet_on_collision_or_bounds
	
	pop 	de
	pop		bc
	pop		hl
	
	jp		.check_for_enemy_collision
	
.destroy_bullet_on_collision_or_bounds
	pop 	de
	pop		bc
	pop		hl
	
	ld		a, $ff
	ld		[hl], a
	
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	
	jp		.update_bullets_pos_loop_end
	
.check_for_enemy_collision
	push 	de
	push	hl
	push	bc
	
	ld		hl, enemy_data
	ld		b, 16		; 6 enemies to update
.check_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .check_enemy_pos_loop_end
	inc		hl
	ld		a, [hl]
	dec		hl
	cp		0
	jp		z, .check_enemy_pos_loop_end

	push	bc
	call	GetSpriteAddress
	pop		bc
	
	inc 	hl
	inc		hl
	ld		a, [hl]
	ld		[current_enemy_width], a
	inc		hl
	ld		a, [hl]
	ld		[current_enemy_height], a
	dec		hl
	dec		hl
	dec		hl
	
	;Check bullet positions in relation to enemy positions and width
	;Check bottom point
	ld		a, [de]
	ld		c, a
	ld		a, [current_bullet_ypos]
	add		8

	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	ld		a, [current_enemy_height]
	ld		c, a
	ld		a, 0
	
.height_loop_start
	add		8
	dec		c
	jr		nz, .height_loop_start
	
	ld		c, a
	ld		a, [de]
	add		c
	ld		c, a
	ld		a, [current_bullet_ypos]
	
	cp 		c
	jr		z, .check_enemy_pos_loop_end
	jr		nc, .check_enemy_pos_loop_end

.check_x_points
	inc		de
	ld		a, [de]
	ld		c, a
	ld		a, [current_bullet_xpos]
	add		8
	dec 	de
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	ld		a, [current_enemy_width]
	ld		c, a
	ld		a, 0
	
.width_loop_start
	add		8
	dec		c
	jr		nz, .width_loop_start
	
	ld		c, a
	inc		de
	ld		a, [de]
	dec 	de
	add		c
	ld		c, a
	ld		a, [current_bullet_xpos]
	
	cp 		c
	jr		z, .check_enemy_pos_loop_end
	jr		nc, .check_enemy_pos_loop_end

.bullet_collided_with_enemy
	inc 	hl
	ld		a, [hl]
	sub		1
	ld		[hl], a
	dec		hl
	cp		0
	jr		nz, .destroy_bullet
	
.destroy_enemy
	call	StartEnemyExplosion

.destroy_bullet
	ld		a, b
	ld		[current_enemy_index], a
	ld		a, h
	ld		[current_enemy_address_upper], a
	ld		a, l
	ld		[current_enemy_address_lower], a
	
	pop		bc
	pop 	hl
	pop		de
	
	ld		a, $ff
	ld		[hl], a
	
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	dec		de
	
	push 	de
	push	hl
	push	bc
	
	ld		a, [current_enemy_index]
	ld		b, a
	ld		a, [current_enemy_address_upper]
	ld		h, a
	ld		a, [current_enemy_address_lower]
	ld		l, a
	
.check_enemy_pos_loop_end
	push	de
	ld		d, 0
	ld		a, [enemy_data_size]
	ld		e, a
	add		hl, de
	pop		de
	
	dec		b
	jp		nz, .check_enemies_pos_loop
	
.done_checking_enemies
	pop		bc
	pop		hl
	pop 	de
	
.update_bullets_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, .update_bullets_pos_loop

	pop		bc
	pop		af
	ret

;-----------------------------------------------------------------
; Find tile index of 
; B = xBottomLeftShipTileIndex, C = yBottomLeftShipTileIndex
;-----------------------------------------------------------------
FindBulletTileIndexes::
	ld		a, [PixelsScrolled]
	ld		b, a
	ld 		a, [current_bullet_xpos]
	sub		8
	add		a, b
	ld		b, -1
	
.XSubLoop
	jr		c, .StartYLoop
	sub		8
	inc 	b
	jp		.XSubLoop

.StartYLoop
	ld 		a, [current_bullet_ypos]
	sub		4
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
	add 	hl, de ;HL now contains the address of the tile at the bottom left bullet co-ordinate
	
	ret