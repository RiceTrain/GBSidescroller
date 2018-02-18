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
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, [hl]
	add		a, 2
	ld		[hl], a
	pop		hl

.update_bullets_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, .update_bullets_pos_loop

	pop		bc
	pop		af
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