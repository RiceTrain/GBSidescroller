InitEnemySprites::
	; init my enemy sprites
	ld		hl, enemy_data
	ld		b, 6		; 6 enemies in table
.init_enemies_loop
	ld 		a, $ff
	ld		[hli], a
	inc		hl
	inc		hl			; 3 bytes per enemy

	dec		b
	jr		nz, .init_enemies_loop
	
	ret
	
;------------------------------------------------------
; update enemy scroll position
;------------------------------------------------------
UpdateEnemyScrollPositions::
	ld		hl, enemy_data
	ld		b, 6		; 6 enemies to update
.update_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_enemies_pos_loop_end

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

.enemy_scroll_left
	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, [hl]
	dec		a
	ld		[hl], a
	pop		hl

.update_enemies_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, .update_enemies_pos_loop
	ret
	
;-------------------------------------------------------------
; Creates an enemy sprite
;-------------------------------------------------------------	
CreateEnemy::
	;store tile id
	ld		a, [hl]
	ld		[NewEnemyTile], a
	
	push	af
	push	de
	push	hl
	
	; find an empty enemy
	ld		hl, enemy_data		; get the addr of the 1st enemy
	ld		b, 6				; 4 enemy slots to check
.find_empty_enemy_loop
	ld		a, [hl]
	cp		$ff			; is this enemy unused
	jr		z, .found_empty_enemy

	inc		hl	; skip 3 bytes, to top of next enemy
	inc		hl
	inc		hl

	dec		b
	jr		nz, .find_empty_enemy_loop

	; no slots left... exit
	pop 	hl
	pop		de
	pop		af
	ret

.found_empty_enemy
	; calc enemy x pos
	ld		a, %11000000 ;192
	ld		d, a
	
	; calc enemy y pos
	ld		a, [CurrentColumnHeight]
	ld		e, a
	ld		a, 34
	sub		e
	ld		e, a
	ld		a, 0
	
.calculate_y_loop
	add		a, 8
	dec		e
	jr		nz, .calculate_y_loop
	
	ld		e, a
	
	; d = x pos
	; e = y pos
	; [NewEnemyTile] = tile number
	; hl = bullet data to launch
	; index into bullet array = 6 - b

	ld		a, [NewEnemyTile]
	ld		[hli], a	; store the tile no
	ld		a, 3
	ld		[hl], a	; all enemies have 3 health

	ld		a, 6
	sub		b		; a = index into bullet array

	push	bc
	
	ld		hl, enemy_sprites	; get top of enemy sprites

	sla		a
	sla		a		; multiply index by 6 (6 bytes per sprite)
	ld		c, a	; store it in de
	ld		b, 0

	add		hl, bc	; I should be pointing at the correct sprite addr

	; load the sprite info
	ld		[hl], e
	inc		hl
	ld		[hl], d
	inc		hl
	ld		a, [NewEnemyTile]
	ld		[hl], a	; bullets use tile 12
	inc		hl
	ld		[hl], 0

	pop 	bc
	pop 	hl
	pop		de
	pop		af
	ret

;------------------------------------------------------
; update enemy positions
;------------------------------------------------------
UpdateEnemyPositions::
	ld		hl, enemy_data
	ld		b, 6		; 6 enemies to update
.update_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_enemies_pos_loop_end

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

.enemy_scroll_left
	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, [hl]
	;dec		a
	ld		[hl], a
	pop		hl

.update_enemies_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, .update_enemies_pos_loop
	ret