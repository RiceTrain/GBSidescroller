;-----------------------------------------
; Get sprite address and store in de
; Expects hl to be at start of enemy_data
;-----------------------------------------
GetSpriteAddress::
	inc		hl
	inc		hl
	ld		a, [hl]
	inc		hl
	inc		hl
	inc		hl
	
	ld		b, $c0
	cp		3 ;is this a boss? (bosses have dimensions 3x3)
	jr		nz, .get_anim_data_address
	
	inc		b
	
.get_anim_data_address
	ld		a, [hl]
	ld		c, a
	
	ld		d, $c0
	ld		a, [bc]
	ld		e, a
	
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	
	ret
	
UpdateEnemyAnimation::
	inc		hl
	ld		a, [hl]
	dec		hl
	cp		0
	jp		z,	.end_update
	
	ld		a, [hl]
	ld		[enemy_tile], a
	inc		hl
	inc		hl
	ld		a, [hl]
	ld		b, a
	inc 	hl
	ld		a, [hl]
	add		a, b
	ld		[enemy_tile_count], a
	inc		hl
	inc		hl
	
	ld		a, b
	ld		b, $c0
	cp		3 ;is this a boss? (bosses have dimensions 3x3)
	jr		nz, .get_anim_data_address
	
	inc		b
	
.get_anim_data_address
	ld		a, [hl]
	ld		c, a
	
	push	hl
	
	ld		h, b
	ld		l, c
	inc		hl
	ld		a, [hl]
	dec		a
	ld		[hl], a
	cp		0
	jr		nz, .reset_hl
	
	dec 	hl
	
	ld		d, $c0
	ld		a, [hl]
	ld		e, a
	
	inc		hl
	inc		hl
	inc		de
	inc		de
	
	ld		a, [enemy_tile_count]
	cp		3
	jr		z, .set_2x1_count
	cp		4
	jr		z, .set_2x2_count
	cp		6
	jr		z, .set_boss_count
	
.set_1x1_count
	ld		b, 1
	ld		c, 1
	jp		.replace_tiles_loop
.set_2x1_count
	ld		b, 2
	ld		c, 2
	jp		.replace_tiles_loop
.set_2x2_count
	ld		b, 4
	ld		c, 4
	jp		.replace_tiles_loop
.set_boss_count
	ld		b, 9
	ld		c, 9
	
.replace_tiles_loop
	ld		a, [de]
	cp		[hl]
	jr		z, .replace_tiles_with_frame_2
	jr		nz, .replace_tiles_with_frame_1
	
.replace_tiles_with_frame_1
	call	ModifySpriteWithData
	jp		.current_tile_check_done
	
.replace_tiles_with_frame_2
	ld		a, c
	
.move_to_next_frame_loop
	inc		hl
	dec		a
	jr		nz, .move_to_next_frame_loop
	
	call	ModifySpriteWithData
	
	ld		a, c
.move_to_current_frame_loop
	dec		hl
	dec		a
	jr		nz, .move_to_current_frame_loop
	
.current_tile_check_done
	dec		b
	jr		z, .reset_timer
	
	inc		hl
	
	inc		de
	inc		de
	inc		de
	inc		de
	
	jp		.replace_tiles_loop
	
.reset_timer
	ld		a, c
.move_to_top_frame_loop
	dec		hl
	dec		a
	jr		nz, .move_to_top_frame_loop
	
	call	GetEnemyAnimTimer
	ld		[hl], a
	
.reset_hl
	pop		hl
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	
.end_update
	ret

ModifySpriteWithData::
	ld		a, [hl]
	
	cp		0
	jr		z, .flip_tile_vertically
	cp		1
	jr		z, .flip_tile_horizontally
	
.replace_with_frame_1
	ld		[de], a
	jp		.end_modification
	
.flip_tile_vertically
	inc		de
	ld		a, [de]
	bit		6, a
	jr		nz, .reset_vertical

.set_vertical
	set 	6, a
	jp		.save_vertical_flag
.reset_vertical
	res 	6, a

.save_vertical_flag
	ld		[de], a
	dec		de
	jp		.end_modification
	
.flip_tile_horizontally
	inc		de
	ld		a, [de]
	bit		5, a
	jr		nz, .reset_horizontal
	
.set_horizontal
	set 	5, a
	jp		.save_horizontal_flag
.reset_horizontal
	res 	5, a
	
.save_horizontal_flag
	ld		[de], a
	dec		de
	
.end_modification
	ret
	
GetEnemyAnimTimer::
	ld		a, [enemy_tile]
	
	cp		18
	jr		z, GetEnemy0AnimTimer
	
	cp		19
	jr		z, GetEnemy0AnimTimer
	ret
	
GetEnemy0AnimTimer::
	ld		a, 120
	ret