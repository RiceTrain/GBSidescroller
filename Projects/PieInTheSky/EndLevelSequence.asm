DisplayLevelEndStats::
	ld		a, 0
	ld		[end_level_sequence_phase], a
	
	push	hl
	push	de
	push	bc
	
	call 	ClearAllSpritesExceptShip
	
	ld		a, 3 ;columns across
	add		a, 160 ;rows down 5 * 32
	ld		c, a
	ld		a, 0
	ld		b, a
	
	ld		hl, MAP_MEM_LOC_1
	add		hl, bc
	ld		de, LevelEndMap
	ld		b, 15
	ld		a, [CurrentTilesetWidth]
	ld		c, a
	
.display_first_line_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_first_line_loop
	
	ld		a, [de]
	add		c
	ld		[hli], a
	inc 	de
	dec 	b
	jr		nz, .display_first_line_loop
	
	ld		c, 49
	add		hl, bc ;add one row and a bit
	
	ld		b, 10
	ld		a, [CurrentTilesetWidth]
	ld		c, a
	
.display_second_line_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_second_line_loop
	
	ld		a, [de]
	add		c
	ld		[hli], a
	inc 	de
	dec 	b
	jr		nz, .display_second_line_loop
	
	ld		a, [enemies_destroyed]
	ld		c, a
	call 	DisplayDigitTen
	
	inc		hl
.wait_for_mode
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_mode
	
	ld 		a, [CurrentTilesetWidth]
	add		2
	add		c
	ld		[hl], a
	
	ld		b, 0
	ld		c, 53
	add		hl, bc ;add one row and a bit
	
	inc		de
	inc		de
	inc		de
	inc		de
	inc		de
	
	ld		b, 10
	ld		a, [CurrentTilesetWidth]
	ld		c, a
	
.display_third_line_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_third_line_loop
	
	ld		a, [de]
	add		c
	ld		[hli], a
	inc 	de
	dec 	b
	jr		nz, .display_third_line_loop
	
	ld		a, [items_collected]
	ld		c, a
	call 	DisplayDigitTen
	
	inc		hl
.wait_for_mode_2
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_mode_2
	
	ld 		a, [CurrentTilesetWidth]
	add		2
	add		c
	ld		[hl], a
	
	ld		b, 0
	ld		c, 53
	add		hl, bc ;add one row and a bit
	
	inc		de
	inc		de
	inc		de
	inc		de
	inc		de
	
	ld		b, 12
	ld		a, [CurrentTilesetWidth]
	ld		c, a
	
.display_fourth_line_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_fourth_line_loop
	
	ld		a, [de]
	add		c
	ld		[hli], a
	inc 	de
	dec 	b
	jr		nz, .display_fourth_line_loop
	
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	
	ld		a, [current_level_completion_bonus]
	ld		c, a
	call 	DisplayDigitHundred
	inc		hl
	call 	DisplayDigitTen
	inc		hl
	
	ld 		a, [CurrentTilesetWidth]
	add		2
	add		c
	ld		[hl], a
	
	pop		bc
	pop		de
	pop		hl
	
	ret

DisplayDigitTen::
	ld 		a, [CurrentTilesetWidth]
	add		2
	ld		b, a
	ld		a, c
	cp		10
	jr		c, .wait_for_non_sprite_mode
	
.calculate_digit_loop
	inc 	b
	ld		a, c
	sub		10
	ld		c, a
	cp		10
	jr		nc, .calculate_digit_loop
	
.wait_for_non_sprite_mode
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_non_sprite_mode
	
	ld		a, b
	ld		[hl], a
	
.end_display
	ret
	
DisplayDigitHundred::
	ld 		a, [CurrentTilesetWidth]
	add		2
	ld		b, a
	ld		a, c
	cp		100
	jr		c, .wait_for_non_sprite_mode
	
.calculate_digit_loop
	inc 	b
	ld		a, c
	sub		100
	ld		c, a
	cp		100
	jr		nc, .calculate_digit_loop
	
.wait_for_non_sprite_mode
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_non_sprite_mode
	
	ld		a, b
	ld		[hl], a
	
.end_display
	ret

Level_Complete_Update::
	ld		a, [end_level_sequence_phase]
	cp		0
	jr		z, .move_window_up
	cp		1
	jr		z, .update_timer
	cp		2
	jr		z, .update_enemy_count_sequence
	cp		3
	jr		z, .update_timer
	cp		4
	jr		z, .update_item_count_sequence
	cp		5
	jr		z, .update_timer
	cp		6
	jp		z, .add_bonus_points
	cp		7
	jr		z, .update_timer
	cp		8
	jp		z, .finish_end_level_sequence

.move_window_up
	ldh		a, [POS_WINDOW_Y]
	dec 	a
	ldh		[POS_WINDOW_Y], a
	cp		0
	jp		nz, .end_update
	
	ld		a, 240
	ld		[end_level_sequence_timer], a
	jp		.increment_phase
	
.update_timer
	ld		a, [end_level_sequence_timer]
	dec		a
	ld		[end_level_sequence_timer], a
	cp		0
	jp 		nz, .end_update
	
	ld		a, 30
	ld		[end_level_sequence_timer], a
	jp		.increment_phase
	
.update_enemy_count_sequence
	ld		a, [end_level_sequence_timer]
	dec		a
	ld		[end_level_sequence_timer], a
	cp		0
	jp 		nz, .end_update
	
	call	StoreScorePositionInHL
	ld		a, [enemies_destroyed]
	dec		a
	ld		c, a
	ld		d, a
	ld		[enemies_destroyed], a
	jr		.store_next_digit
	
.update_item_count_sequence
	ld		a, [end_level_sequence_timer]
	dec		a
	ld		[end_level_sequence_timer], a
	cp		0
	jr 		nz, .end_update
	
	call	StoreItemPositionInHL
	ld		a, [items_collected]
	dec		a
	ld		c, a
	ld		d, a
	ld		[items_collected], a
	
.store_next_digit
	call 	DisplayDigitTen
	inc		hl
	
.wait_for_mode
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .wait_for_mode
	
	ld 		a, [CurrentTilesetWidth]
	add		2
	add		c
	ld		[hl], a
	
	ld		a, 10
	call	AddAToCurrentScore
	
	ld		a, d
	cp 		0
	jr		z, .increment_timer_for_next_phase
	
.increment_timer_for_next_deduction
	ld		a, 8
	ld		[end_level_sequence_timer], a
	jr		.end_update
	
.increment_timer_for_next_phase
	ld		a, 60
	ld		[end_level_sequence_timer], a
	jr		.increment_phase
	
.add_bonus_points
	call 	StoreBonusPositionInHL
	ld 		a, [CurrentTilesetWidth]
	add		2
	ld		c, a
	ld		b, 4
	
.display_bonus_loop
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_bonus_loop
	
	ld		a, c
	ld		[hli], a
	dec		b
	jr		nz, .display_bonus_loop
	
	ld		a, [current_level_completion_bonus]
	call	AddAToCurrentScore
	
	ld		a, 120
	ld		[end_level_sequence_timer], a
	jr		.increment_phase
	
.finish_end_level_sequence
	ld		a, 0
	ld		[end_level_sequence_phase], a
	call 	LoadNextLevel
	jr		.move_ship_finished
	
.increment_phase
	ld		a, [end_level_sequence_phase]
	inc		a
	ld		[end_level_sequence_phase], a
	
.end_update
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .end_update
	
	call	StoreCurrentPlayerAnimAddress
	call 	StoreCurrentGunSpriteAddr
	ld		a, [de]
	ld		b, a
	ld		a, [spaceshipL_ypos]
	ld		c, a
	cp		128
	jr		z, .move_ship_x
	jr		nc, .move_y_up
	
	inc		c
	inc 	b
	jr		.store_new_y
	
.move_y_up
	dec		c
	dec		b
.store_new_y
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .store_new_y
	
	ld		a, c
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	ld		[hl], a
	ld		a, b
	ld		[de], a
	
.move_ship_x
	inc		hl
	inc		de
	ld		a, [de]
	ld		c, a
	ld		a, [spaceshipL_xpos]
	ld		b, a
	cp		80
	jr		z, .move_ship_finished
	jr		nc, .move_x_left
	
	inc 	b
	inc		c
	jr		.store_new_x
	
.move_x_left
	dec		b
	dec		c
	
.store_new_x
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .store_new_x
	
	ld		a, b
	ld		[spaceshipL_xpos], a
	add 	8
	ld		[spaceshipR_xpos], a
	sub 	16
	ld		[hl], a
	ld		a, c
	ld		[de], a
	
.move_ship_finished
	ret
	
StoreScorePositionInHL::
	call	StoreTopLeftPositionInHL
	
	;get to score location here
	ld		a, 64
	add		10
	ld		c, a
	ld		b, 0
	add		hl, bc
	ld		b, h
	ld		c, l
	
	ld		hl, MAP_MEM_LOC_1
	add		hl, bc
	
	ret
	
StoreItemPositionInHL::
	call	StoreTopLeftPositionInHL
	
	;get to score location here
	ld		a, 128
	add		10
	ld		c, a
	ld		b, 0
	add		hl, bc
	ld		b, h
	ld		c, l
	
	ld		hl, MAP_MEM_LOC_1
	add		hl, bc
	
	ret
	
StoreBonusPositionInHL::
	call	StoreTopLeftPositionInHL
	
	;get to score location here
	ld		a, 192
	add		8
	ld		c, a
	ld		b, 0
	add		hl, bc
	ld		b, h
	ld		c, l
	
	ld		hl, MAP_MEM_LOC_1
	add		hl, bc
	
	ret
	
StoreTopLeftPositionInHL::
	;get top left starting point here
	ld		a, 3 ;columns across
	add		a, 160 ;rows down 5 * 32
	ld		l, a
	ld		h, 0
	
	ret
	
ClearAllSpritesExceptShip::
	call	Wait_For_Vblank
	ld		a, 0
	ld		[vblank_flag], a
	
	ld		hl, $c018	; my sprites are at $c000, exclude ship sprites
	ld		b, 34*4		; 40 sprites, 4 bytes per sprite
	ld		a, 0
.init_sprites_loop
	ld		[hli], a
	dec		b
	jr		nz, .init_sprites_loop
	
	ret
	
LoadNextLevel::
	ld		a, [level_count]
	ld		b, a
	
	ld		a, [level_no]
	inc 	a
	ld		[level_no], a
	cp 		b
	jr		z, .start_game_end
	
	call	Wait_For_Vblank
	call	InitLevelStart
	jr		.end_load_level
	
.start_game_end
	call	Setup_Game_End
	
.end_load_level
	ret
	
Setup_Game_End::
	ld		a, 2
	ld		[game_state], a
	
	call 	SaveHiScore
	
	call 	CLEAR_MAP
	
	call	Wait_For_Vblank
	call	InitSprites
	
	ld		a, 40
	ld 		[CurrentTilesetWidth], a
	ld		bc, MainMenuTiles
	call 	LoadTiles
	
	ld		a, 0
	ldh		[POS_WINDOW_Y], a
	ld		a, 7
	ldh		[POS_WINDOW_X], a
	
	call 	LoadEndGameMap
	
	ret
	
LoadEndGameMap::
	ld		hl, MAP_MEM_LOC_1
	ld		de, GameEndMap
	ld		b, 20
	ld		c, 18
	
.display_tiles_loop
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .display_tiles_loop
	
	ld		a, [de]
	ld		[hli], a
	
	inc 	de
	dec		b
	jr		nz, .display_tiles_loop
	
	push 	bc
	ld		bc, 12
	add 	hl, bc
	pop 	bc
	
	ld		b, 20
	dec		c
	jr		nz, .display_tiles_loop
	
	ret
	
End_Game_Update::
	ld		a, [joypad_down]
	bit		START_BUTTON, a
	jp		z, .end_update	; if button not pressed then done
	
	ld		a, 0
	ld		[game_state], a
	
	call	CLEAR_WINDOW_MAP
	call	Setup_Main_Menu
	
.end_update
	ret