InitBulletSprites::
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
	
;Called after enemy sprites are initialised, hl is at correct address here
InitBombSprite::
	ld		hl, bomb_data
	ld 		a, $ff
	ld		[hl], a 
	
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
	; calc bullet x launch pos
	ld		a, [spaceshipR_xpos]
	add     a, 8
	ld		b, a
	; calc bullet y launch pos
	ld		a, [spaceshipR_ypos]
	add		a, 2
	ld		c, a
	; direction is right
	ld		a, 2
	
	; a = orientation
	; b = x pos
	; c = y pos
	; hl = bullet data to launch
	; index into bullet array = 16 - d

	ld		[hli], a	; store the orientation
	ld		[hl], 60	; bullet lasts 1 second (60 vblanks)

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
	ld		[hl], 12	; bullets use tile 12
	inc		hl
	ld		[hl], 0

	pop		de
	pop		bc
	pop		af
	ret
	
;------------------------------------------------------------
; launch a bomb
;------------------------------------------------------------
LaunchBomb::
	ld		hl, bomb_data
	ld		a, [hl]
	cp		$ff			; is this bomb unused
	jr 		nz, .exit_bomb_launch
	
	ld		a, 1
	ld		[hli], a	; store the x speed
	ld		[hl], 60	; bomb lasts 1 second (60 vblanks)
	
	; calc bomb x launch pos
	ld		a, [spaceshipR_xpos]
	add     a, 8
	ld		[bomb_xpos], a
	
	; calc bomb y launch pos
	ld		a, [spaceshipR_ypos]
	add		a, 2
	ld		[bomb_ypos], a
	
	; load the sprite info
	ld		a, 13
	ld		[bomb_sprite], a	; bombs use tile 13
	ld		a, 0
	ld		[bomb_flags], a
	
.exit_bomb_launch
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

;-----------------------------------------------------------------
; update the bomb timing ever vblank
;-----------------------------------------------------------------
UpdateBombTimer::
	ld		hl, bomb_data
	ld		a, [hli]
	cp		$ff
	jr		z, .update_bomb_end
	
	; bomb is active
	dec		[hl]	; decrement the timer
	jr		nz, .update_bomb_end

	dec 	hl
	ld		a, $ff
	ld		[hl], a
	
	ld		a, $00
	ld		[bomb_ypos], a
	ld		[bomb_xpos], a		; turn off the sprite in the attrib table
	
.update_bomb_end
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

.bullet_fly_right
	; update this sprite's position
	ld		a, [de]
	ld		[current_bullet_ypos], a
	inc		de
	ld		a, [de]
	add		a, 2
	ld		[current_bullet_xpos], a
	ld		[de], a
	dec		de
	
	push	hl
	push	bc
	push	de
	
	call FindBulletTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .destroy_bullet_on_collision

	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .destroy_bullet_on_collision
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .destroy_bullet_on_collision
	
	dec		hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .destroy_bullet_on_collision
	
	pop 	de
	pop		bc
	pop		hl
	
	jp		.check_for_enemy_collision
	
.destroy_bullet_on_collision
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
	
	;Check bullet positions in relation to enemy positions and width
	ld		a, [de]
	ld		c, a
	ld		a, [current_bullet_ypos]
	add		4 ;get center of bullet sprites

	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	ld		a, c
	add		8
	ld		c, a
	ld		a, [current_bullet_ypos]
	add		4 ;get center of bullet sprites
	
	cp 		c
	jr		z, .check_enemy_pos_loop_end
	jr		nc, .check_enemy_pos_loop_end
	
	inc		de
	ld		a, [de]
	ld		c, a
	ld		a, [current_bullet_xpos]
	add		4 ;get center of bullet sprites
	dec 	de
	
	cp		c
	jr		z, .check_enemy_pos_loop_end
	jr		c, .check_enemy_pos_loop_end
	
	ld		a, c
	add		8
	ld		c, a
	ld		a, [current_bullet_xpos]
	add		4 ;get center of bullet sprites
	
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
	ld		a, $ff
	ld		[hl], a
	
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a

.destroy_bullet
	pop		de
	pop 	hl
	
	ld		a, $ff
	ld		[hl], a
	
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	dec		de
	
	push	hl
	push 	de
	
.check_enemy_pos_loop_end
	inc		hl
	inc		hl
	inc		hl
	inc		hl
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
	sub		4
	add		a, b
	ld		b, -1
	
.XSubLoop
	jr		c, .StartYLoop
	sub		8
	inc 	b
	jp		.XSubLoop

.StartYLoop
	ld 		a, [current_bullet_ypos]
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
	add 	hl, de ;HL now contains the address of the tile at the bottom left bullet co-ordinate
	
	ret
	
;------------------------------------------------------
; update bomb position
;------------------------------------------------------
UpdateBombPosition::
	ld		hl, bomb_data
	ld		a, [hl]
	cp		$ff
	jp		z, .update_bomb_pos_end
	
	ld		a, [bomb_xpos]
	add		a, 2
	ld		[bomb_xpos], a
	
.update_bomb_pos_end
	ret