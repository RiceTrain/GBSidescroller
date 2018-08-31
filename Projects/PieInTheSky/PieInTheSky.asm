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
	
	ld		a, 38
	ld		[TestMapBlockTotal], a
	ld		a, 9
	ld		[enemy_data_size], a
	
	ld		a, 0
	ld		[vblank_flag], a
	
	call	Wait_For_Vblank
	
	ld		a, 138
	ldh		[POS_WINDOW_Y], a
	ld		a, 0
	ldh		[POS_WINDOW_X], a
	
	call	InitLevelStart
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
	
	call	AnimateShip
	
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
  
InitLevelStart::
	call 	InitWorkingVariables
	call 	InitLevel
	
	ld		a, 0
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	ld		[checkpoint_map_block], a
	ld		[checkpoint_tiles_scrolled], a
	ld		hl, TestMap
	call	LoadMapToBkg
	
	call 	LoadMapToWindow
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	ld		a, 76
	ld		[checkpoint_ship_y], a
	call 	InitPlayerSprite
	
	ret
	
InitWorkingVariables::
	ld		a, 0
	ld		[vblank_flag], a
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	ld		[ScrollTimer], a
	ld		[joypad_held], a
	ld		[joypad_down], a
	ld		[current_score], a
	ld		[score_tracker_lower], a
	ld		[score_tracker_higher], a
	
	ld		a, $ff
	ld		[checkpoint_pixels], a
	
	ld		a, 3
	ld		[lives], a
	
	ret

Level_Complete_Update::

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
;TODO: Check for game over
	call	ResetPlayerOnDeath
	jr		.dead_update_end
	
.animate_explosion
	cp		110
	jr		z, PlayerDeathFrame2
	
	cp		100
	jr		z, PlayerDeathFrame3
	
	cp		80
	jr		z, PlayerDeathFrame4
	
	cp		70
	jr		z, PlayerDeathFrame5
	
	cp		60
	jr		z, PlayerDeathFrame6
	
.dead_update_end
	ret
	
ResetPlayerOnDeath::
	call 	InitWorkingVariables
	
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
; Tiles are here
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyTiles.z80"
INCLUDE "Projects/PieInTheSky/Data/WinTiles.z80"
; Music is here
INCLUDE "Projects/PieInTheSky/Data/CWGB.asm"

INCLUDE "Projects/PieInTheSky/Variables.asm"