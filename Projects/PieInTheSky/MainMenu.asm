Setup_Main_Menu::
	ld		a, 0
	ld		[game_state], a
	
	call 	InitPlayerData
	ld		a, 76
	ld		[checkpoint_ship_y], a
	call	InitSprites
	
	call 	CLEAR_MAP
	
	ld		a, 40
	ld 		[CurrentTilesetWidth], a
	ld		bc, MainMenuTiles
	call 	LoadTiles
	
	ld		a, 0
	ldh		[POS_WINDOW_Y], a
	ld		a, 7
	ldh		[POS_WINDOW_X], a
	call 	LoadMainMenuMap
	
	call 	InitPlayerSprite
	
	ret
	
LoadMainMenuMap::
	ld		hl, MAP_MEM_LOC_1
	ld		de, MainMenuMap
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
	
	call	Display_Hi_Score
	
	ret
	
Display_Hi_Score::
	ld		a, 0
	ld		[current_score], a
	ld		a, 0
	ld		[score_tracker_lower], a
	ld		a, 0
	ld		[score_tracker_higher], a
	
	ld		a, [high_score_tracker_higher]
	cp 		0
	jr		z, .add_current_score
	
	ld		e, a
	ld		a, [high_score_tracker_lower]
	ld		d, a
	
.add_score_loop
	call	StoreHiScorePositionInHL
	ld		b, $ff
	call	UpdateScoreDisplay
	dec		e
	jr		nz, .add_score_loop
	ld		e, $ff
	dec		d
	jr		z, .add_score_loop
	
.add_current_score
	call	StoreHiScorePositionInHL
	ld		a, [high_current_score]
	ld		b, a
	call	UpdateScoreDisplay
	
	ret
	
StoreHiScorePositionInHL::
	ld		a, 12 ;columns across
	add		a, 224 ;rows down 7 * 32
	ld		l, a
	ld		h, 0
	
	push 	bc
	
	;get to hi score end location here
	ld		a, 185
	ld		c, a
	ld		b, 0
	add		hl, bc
	ld		b, h
	ld		c, l
	
	ld		hl, MAP_MEM_LOC_1
	add		hl, bc
	
	pop 	bc
	
	ret
	
Main_Menu_Update::
	ld		a, [joypad_down]
	bit		START_BUTTON, a
	jp		z, .end_update	; if button not pressed then done
	
	ld		a, 1
	ld		[game_state], a
	
	call 	CLEAR_WINDOW_MAP
	call	NewGameStart
	
.end_update
	ret