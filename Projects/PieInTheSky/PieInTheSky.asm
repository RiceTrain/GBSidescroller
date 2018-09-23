; Pie in the Sky
; by Rhys Thomas
; based off examples by opus@dnai.com

INCLUDE "Projects/PieInTheSky/Constants.asm"

SECTION	"Game_Code_Start",ROM0[$0150]
; begining of game code
start::
	ei
	; init the stack pointer
	ld		sp, STACK_TOP
	
	; enable only vblank interrupts
	ld		a, VBLANK_INT			; set vblank interrupt bit
	ldh		[INTERRUPT_ENABLE], a	; load it to the hardware register

	ld		a, 0
	ld		[vblank_flag], a
	
	call	Wait_For_Vblank
	
	; standard inits
	sub		a	;	a = 0
	ldh		[LCDC_STATUS], a	; init status
	ldh		[LCDC_CONTROL], a	; init LCD to everything off
	
	call	CLEAR_MAP
	call 	CLEAR_OAM
	call 	CLEAR_RAM
	
	; set display to on, background on, window off, sprites on, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG | BKG_DISP_FLAG | SPRITE_DISP_FLAG | TILES_LOC | WINDOW_DISP_FLAG | WINDOW_MAP_LOC
	ldh		[LCDC_CONTROL],a

	ld		a, 0
	ld		[vblank_flag], a
	
	call	Wait_For_Vblank
	
	call	InitWorkingVariablesOnStartup
	
	ld		a, 136
	ldh		[POS_WINDOW_Y], a
	ld		a, 7
	ldh		[POS_WINDOW_X], a
	
	call	NewGameStart
	call 	InitSoundChannels
	
	ld		a, 0
	ld		[vblank_flag], a
	
	call 	DMA_COPY

; main game loop
Game_Loop::
	halt
	nop
	
	call	Wait_For_Vblank
	
	; reset vblank flag
	ld		a, 0
	ld		[vblank_flag], a
	
	; get this frame's joypad info
	call	ReadJoypad
	
	call 	Main_Game
	
	call	AnimateShip
	
	call	$FF80
	jr		Game_Loop

Main_Game::
	ld		a, [alive]
	cp 		1
	jr		z, .check_for_end_level
	
	call 	Player_Dead_Update
	jr		.end_main_update

.check_for_end_level
	ld		a, [level_end_reached]
	cp		0
	jr		z, .do_main_update
	ld		a, [boss_defeated]
	cp		0
	jr		z, .do_main_update
	
	call	Level_Complete_Update
	jr		.end_main_update
	
.do_main_update
	call	Main_Game_Loop

.end_main_update
	ret

Main_Game_Loop::
	call 	ScrollLevel
	call 	UpdateBulletTimers
	
	; update any active bullets
	; do this before MoveSpaceship, since we want the bullet to display at
	; its launch position for one frame
	call 	UpdateBulletPositions
	call 	UpdateEnemyBehaviours
	
	; adjust sprite due to d-pad presses
	call	MoveSpaceship
	
	call    gbt_update ; Update player
	
	ret
	
CLEAR_MAP::
  ld  hl, MAP_MEM_LOC_0
  ld  bc, $400
  push hl

.clear_map_loop
  ;wait for hblank
  ld  h, $ff
  ld  l, LCDC_STATUS
  bit 1,[hl]
  jr  nz,.clear_map_loop
  pop hl

  ld  a,$0
  ld  [hli],a
  push hl
  
  dec bc
  ld  a,b
  or  c
  jr  nz,.clear_map_loop
  pop hl
  ret

CLEAR_OAM::
  ld  hl, SPRITE_ATTRIB_MEM_LOC
  ld  bc, $A0
.clear_oam_loop
  ld  a,$0
  ld  [hli],a
  dec bc
  ld  a,b
  or  c
  jr  nz,.clear_oam_loop
  ret

CLEAR_RAM::
  ld  hl,$C100
  ld  bc,$A0
.clear_ram_loop
  ld  a,$0
  ld  [hli],a
  dec bc
  ld  a,b
  or  c
  jr  nz,.clear_ram_loop
  ret

InitWorkingVariablesOnStartup::
	ld		a, 0
	ld		[joypad_held], a
	ld		[joypad_down], a
	
	ld		a, 9
	ld		[enemy_data_size], a
	
	ret
	
NewGameStart::
	call 	InitWorkingVariablesOnNewGame
	call 	InitLevelStart
	
	call 	LoadMapToWindow
	
	ret

InitWorkingVariablesOnNewGame::
	ld		a, 0
	ld		[level_no], a
	ld		[current_score], a
	ld		[score_tracker_lower], a
	ld		[score_tracker_higher], a
	ld		[checkpoint_current_score], a
	ld		[checkpoint_score_tracker_lower], a
	ld		[checkpoint_score_tracker_higher], a
	
	ld		a, 3
	ld		[lives], a
	
	ret
	
InitLevelStart::
	call 	InitWorkingVariablesOnLevelStart
	call 	InitLevel
	
	ld		a, 0
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	ld		[checkpoint_map_block], a
	ld		[checkpoint_tiles_scrolled], a
	call	LoadCurrentMapIntoHL
	call	LoadMapToBkg
	
	call 	UpdateLivesDisplay
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	ld		a, 76
	ld		[checkpoint_ship_y], a
	call 	InitPlayerSprite
	
	ret

InitWorkingVariablesOnLevelStart::
	ld		a, 0
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	ld		[ScrollTimer], a
	ld		[joypad_held], a
	ld		[joypad_down], a
	ld		[enemies_destroyed], a
	ld		[items_collected], a
	
	ld		[checkpoint_enemies_destroyed], a
	ld		[checkpoint_items_collected], a
	ld		a, $ff
	ld		[checkpoint_pixels], a
	
	ret

LoadCurrentMapIntoHL::
	ld		a, [level_no]
	
	cp		0
	jr		z, .load_level_1
	
.load_level_1
	ld		a, 38
	ld		[CurrentMapBlockTotal], a
	ld		a, 152
	ld		[current_level_completion_bonus], a
	ld		hl, TestMap
.map_loaded
	ret

DisplayLevelEndStats::
	ld		a, 0
	ld		[end_level_sequence_phase], a
	
	push	hl
	push	de
	push	bc
	
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
	
	ld		b, 11
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
	ld		a, 15
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
	jr		.end_update
	
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
	
LoadNextLevel::
	ld		a, [level_no]
	inc 	a
	ld		[level_no], a
	
	ret
	
Player_Dead_Update::
	ld		a, [death_timer]
	dec		a
	ld		[death_timer], a
	cp		0
	jp		nz, .animate_explosion

.check_game_over
	ld		a, [lives]
	cp		0
	jr		nz, .reset_player
	
	;start game over sequence
	
.reset_player
	call	ResetPlayerOnDeath
	jr		.dead_update_end
	
.animate_explosion
	cp		110
	jr		z, PlayerDeathFrame2
	
	cp		100
	jp		z, PlayerDeathFrame3
	
	cp		80
	jr		z, PlayerDeathFrame4
	
	cp		70
	jp		z, PlayerDeathFrame5
	
	cp		60
	jp		z, PlayerDeathFrame6
	
.dead_update_end
	ret
	
ResetPlayerOnDeath::
	call 	InitWorkingVariablesOnDeath
	
	ld		a, 0
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	ld		hl, TestMap
	call	LoadMapToBkg
	
	ld		a, 0
	ld		[level_end_reached], a
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	call 	InitPlayerSprite
	
	call 	ResetScoreToCheckpoint
	call 	UpdateLivesDisplay
	
	call	ResetStatsToCheckpoint
	
	ret
	
InitWorkingVariablesOnDeath::
	ld		a, 0
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	ld		[ScrollTimer], a
	ld		[joypad_held], a
	ld		[joypad_down], a
	ld		[enemies_destroyed], a
	ld		[items_collected], a
	
	ret
	
ResetStatsToCheckpoint::
	ld		a, [checkpoint_enemies_destroyed]
	ld		[enemies_destroyed], a
	ld		a, [checkpoint_items_collected]
	ld		[items_collected], a
	
	ret
	
PlayerDeathFrame2::
	ld		a, 21
	ld		[spaceshipL_tile], a
	ret
	
PlayerDeathFrame4::
	ld		a, 21
	ld		[spaceshipL_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 4
	ld		[spaceshipL_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 4
	ld		[spaceshipL_ypos], a
	
	ld		a, 0
	ld		[spaceshipR_ypos], a
	ld		[spaceshipR_xpos], a
	ld		[spaceshipLAnim1_ypos], a
	ld		[spaceshipLAnim1_xpos], a
	ld		[spaceshipLAnim2_ypos], a
	ld		[spaceshipLAnim2_xpos], a
	
	ret
	
PlayerDeathFrame5::
	ld		a, 20
	ld		[spaceshipL_tile], a
	ret
	
PlayerDeathFrame6::
	ld		a, 0
	ld		[spaceshipL_xpos], a
	ld		[spaceshipL_ypos], a
	ret

PlayerDeathFrame3::
	ld		a, 22
	ld		[spaceshipL_tile], a
	ld		a, [spaceshipL_xpos]
	sub		4
	ld		[spaceshipL_xpos], a
	ld		a, [spaceshipL_ypos]
	sub		4
	ld		[spaceshipL_ypos], a
	
	ld		a, 22
	ld		[spaceshipR_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 8
	ld		[spaceshipR_xpos], a
	ld		a, [spaceshipL_ypos]
	ld		[spaceshipR_ypos], a
	ld		a, [spaceshipR_flags]
	set 	5, a
	ld		[spaceshipR_flags], a
	
	ld		a, 22
	ld		[spaceshipLAnim1_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 8
	ld		[spaceshipLAnim1_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 8
	ld		[spaceshipLAnim1_ypos], a
	ld		a, [spaceshipLAnim1_flags]
	set 	5, a
	set 	6, a
	ld		[spaceshipLAnim1_flags], a
	
	ld		a, 22
	ld		[spaceshipLAnim2_tile], a
	ld		a, [spaceshipL_xpos]
	ld		[spaceshipLAnim2_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 8
	ld		[spaceshipLAnim2_ypos], a
	ld		a, [spaceshipLAnim2_flags]
	set 	6, a
	ld		[spaceshipLAnim2_flags], a
	
	ret

DMA_COPY::
  ; load de with the HRAM destination address
  ld  de,$FF80

  rst $28

  ; the amount of data we want to copy into HRAM, $000D which is 13 bytes
  DB  $00,$0D

  ; this is the above DMA subroutine hand assembled, which is 13 bytes long
  DB  $F5, $3E, $C0, $EA, $46, $FF, $3E, $28, $3D, $20, $FD, $F1, $D9
  ret
  
Wait_For_Vblank::
	ld		a, [vblank_flag]
	cp		0
	jr		z, Wait_For_Vblank
	ret
	
Wait_For_Vram::
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE		; don't write during sprite and transfer modes
	jr		nz, Wait_For_Vram
	ret
	
;---------------------------------------------------
; my vblank routine - do all graphical changes here
; while the display is not drawing
;---------------------------------------------------
VBlankFunc::
	push	af
	push    bc
    push    de
    push    hl

	; set the vblank occured flag
	ld		a, 1
	ld		[vblank_flag], a
	
	pop     hl
	pop     de
	pop     bc
	pop 	af
	reti	; and done

INCLUDE "Projects/PieInTheSky/Input.asm"
INCLUDE "Projects/PieInTheSky/Player.asm"
INCLUDE "Projects/PieInTheSky/Projectiles.asm"
INCLUDE "Projects/PieInTheSky/Enemies.asm"
INCLUDE "Projects/PieInTheSky/Score.asm"
INCLUDE "Projects/PieInTheSky/SoundPlayer.asm"
INCLUDE "Projects/PieInTheSky/Level.asm"
INCLUDE "Projects/PieInTheSky/WindowHandler.asm"

; Map is here
INCLUDE "Projects/PieInTheSky/Data/TestMap.z80"
INCLUDE "Projects/PieInTheSky/Data/WindowMap.z80"
INCLUDE "Projects/PieInTheSky/Data/LevelEndMap.z80"
; Tiles are here
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyTiles.z80"
INCLUDE "Projects/PieInTheSky/Data/WinTiles.z80"
; Music is here
INCLUDE "Projects/PieInTheSky/Data/CWGB.asm"

INCLUDE "Projects/PieInTheSky/Variables.asm"