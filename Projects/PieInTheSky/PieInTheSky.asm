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
	
	call 	SetLCDDisplay

	ld		a, 0
	ld		[vblank_flag], a
	
	call	Wait_For_Vblank
	
	ld		a, 0
	ld		[vblank_flag], a
	
	call	InitWorkingVariablesOnStartup
	call	InitPalettes
	call	Setup_Main_Menu
	
	call 	InitSoundChannels
	
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
	
	ld		a, [game_state]
	cp		1
	jr		z, .update_main_game
	cp		2
	jr		z, .update_end_game
	
	call 	Main_Menu_Update
	jr		.vblank_routine
	
.update_main_game
	call 	Main_Game
	jr		.vblank_routine
	
.update_end_game
	call 	End_Game_Update
	
.vblank_routine
	call	AnimateShip
	call	$FF80
	jr		Game_Loop

SetLCDDisplay::
	; set display to on, background on, window off, sprites on, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG | BKG_DISP_FLAG | SPRITE_DISP_FLAG | TILES_LOC | WINDOW_DISP_FLAG | WINDOW_MAP_LOC
	ldh		[LCDC_CONTROL],a
	
	ret
	
InitWorkingVariablesOnStartup::
	ld		a, 0
	ld		[joypad_held], a
	ld		[joypad_down], a
	ld		[game_state], a
	ld		[game_paused], a
	ld		[high_current_score], a
	ld		[high_score_tracker_lower], a
	ld		[high_score_tracker_higher], a
	
	ld		a, 10
	ld		[enemy_data_size], a
	
	ld		a, 1
	ld		[level_count], a
	
	ret

Main_Game::
	ld		a, [alive]
	cp 		1
	jr		z, .check_for_end_level
	
	ld		a, [game_over_sequence_timer]
	cp 		0
	jr		z, .animate_player_death
	
	call	Game_Over_Update
	jr		.end_main_update
	
.animate_player_death
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
	call 	CheckForPause
	ld		a, [game_paused]
	cp		1
	jr		z, .end_update
	
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
	
.end_update
	ret
	
CheckForPause::
	ld		a, [joypad_down]
	bit		START_BUTTON, a
	jr		z, .end_update	; if button not pressed then done
	
	ld		a, [game_paused]
	cp		0
	jr		z, .set_paused_on
	
	ld		a, 0
	ld		[game_paused], a
	
	call	Wait_For_Vram
	call	SetLCDDisplay
	
	jr		.end_update
	
.set_paused_on
	ld		a, 1
	ld		[game_paused], a
	
	call	Wait_For_Vram
	call	SetLCDDisplayNoSprites
	
.end_update
	ret
	
SetLCDDisplayNoSprites::
	; set display to on, background on, window off, sprites off, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG | BKG_DISP_FLAG | TILES_LOC | WINDOW_DISP_FLAG | WINDOW_MAP_LOC
	ldh		[LCDC_CONTROL],a
	
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
	
NewGameStart::
	call 	InitWorkingVariablesOnNewGame
	call 	InitLevelStart
	
	call 	LoadMapToWindow
	call 	UpdateLivesDisplay
	
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
	ld		[level_end_reached], a
	ld		[boss_defeated], a
	ld		[game_over_sequence_timer], a
	
	ld		a, 3
	ld		[lives], a
	
	ret
	
InitLevelStart::
	call 	InitWorkingVariablesOnLevelStart
	call 	InitLevel
	
	ld		a, 136
	ldh		[POS_WINDOW_Y], a
	ld		a, 7
	ldh		[POS_WINDOW_X], a
	
	ld		a, 0
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	ld		[checkpoint_map_block], a
	ld		[checkpoint_tiles_scrolled], a
	call	LoadCurrentMapIntoHL
	call	LoadMapToBkg
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	call 	InitPlayerSprite
	
	ld		a, [current_score]
	ld		[checkpoint_current_score], a
	ld		a, [score_tracker_lower]
	ld		[checkpoint_score_tracker_lower], a
	ld		a, [score_tracker_higher]
	ld		[checkpoint_score_tracker_higher], a
	
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
	ld		[current_level_enemy_count], a
	
	ld		[level_end_reached], a
	ld		[boss_defeated], a
	ld		[checkpoint_enemies_destroyed], a
	ld		[checkpoint_items_collected], a
	ld		[checkpoint_enemy_count], a
	
	ld		a, 76
	ld		[checkpoint_ship_y], a
	
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
	ld		a, 100
	ld		[current_level_completion_bonus], a
	
	ld		hl, EnemyBehaviourData
	ld		a, h
	ld		[current_level_enemy_data_upper], a
	ld		a, l
	ld		[current_level_enemy_data_lower], a
	
	ld		a, 10
	ld		[current_level_enemy_length], a
	
	ld		hl, TestMap
.map_loaded
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

INCLUDE "Projects/PieInTheSky/MainMenu.asm"
INCLUDE "Projects/PieInTheSky/EndLevelSequence.asm"
INCLUDE "Projects/PieInTheSky/PlayerDeathSequence.asm"

INCLUDE "Projects/PieInTheSky/Input.asm"
INCLUDE "Projects/PieInTheSky/Player.asm"
INCLUDE "Projects/PieInTheSky/Projectiles.asm"
INCLUDE "Projects/PieInTheSky/Enemies.asm"
INCLUDE "Projects/PieInTheSky/Score.asm"
INCLUDE "Projects/PieInTheSky/SoundPlayer.asm"
INCLUDE "Projects/PieInTheSky/Level.asm"
INCLUDE "Projects/PieInTheSky/WindowHandler.asm"

; Map is here
INCLUDE "Projects/PieInTheSky/Data/MainMenuMap.z80"
INCLUDE "Projects/PieInTheSky/Data/TestMap.z80"
INCLUDE "Projects/PieInTheSky/Data/WindowMap.z80"
INCLUDE "Projects/PieInTheSky/Data/LevelEndMap.z80"
INCLUDE "Projects/PieInTheSky/Data/GameEndMap.z80"
; Tiles are here
INCLUDE "Projects/PieInTheSky/Data/MainMenuTiles.z80"
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyTiles.z80"
INCLUDE "Projects/PieInTheSky/Data/WinTiles.z80"
INCLUDE "Projects/PieInTheSky/Data/GameOverMap.z80"
; Music is here
INCLUDE "Projects/PieInTheSky/Data/CWGB.asm"

INCLUDE "Projects/PieInTheSky/Variables.asm"