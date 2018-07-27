; Pie in the Sky
; by Rhys Thomas
; based off examples by opus@dnai.com

INCLUDE "Projects/PieInTheSky/Constants.asm"

SECTION	"Game_Code_Start",HOME[$0150]
; begining of game code
start::
	di
	; init the stack pointer
	ld		sp, STACK_TOP
	
	; enable only vblank interrupts
	ld		a, VBLANK_INT			; set vblank interrupt bit
	ldh		[INTERRUPT_ENABLE], a	; load it to the hardware register

	ld		a, 0
	ld		[vblank_flag], a
	
	; allow interrupts to start occuring
	ei
	
.wait_for_vblank
	ld		a, [vblank_flag]
	cp		0
	jr		z, .wait_for_vblank
	
	di
	
	; standard inits
	sub		a	;	a = 0
	ldh		[LCDC_STATUS], a	; init status
	ldh		[LCDC_CONTROL], a	; init LCD to everything off
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	
	ld		a, 38
	ld		[TestMapBlockTotal], a
	ld		a, 8
	ld		[enemy_data_size], a
	
	call	InitLevelStart
	
	; set display to on, background on, window off, sprites on, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG | BKG_DISP_FLAG | SPRITE_DISP_FLAG | TILES_LOC | WINDOW_MAP_LOC
	ldh		[LCDC_CONTROL],a
	
	call 	InitSoundChannels
	
	ld		a, 0
	ld		[vblank_flag], a
	
	call 	DMA_COPY
	ei

; main game loop
Game_Loop::
	; don't do a frame update unless we have had a vblank
	ld		a, [vblank_flag]
	cp		0
	jr		z, Game_Loop
	
	; reset vblank flag
	ld		a, 0
	ld		[vblank_flag], a
	
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
	
	; get this frame's joypad info
	call	ReadJoypad

	; update any active bullets
	; do this before MoveSpaceship, since we want the bullet to display at
	; its launch position for one frame
	call 	UpdateBulletPositions
	call 	UpdateEnemyBehaviours
	
	; adjust sprite due to d-pad presses
	call	MoveSpaceship
	
	call	AnimateShip
	
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
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	ld		a, 76
	ld		[checkpoint_ship_y], a
	call 	InitPlayerSprite
	
	ret
	
Level_Complete_Update::

	ret
	
Player_Dead_Update::
	ld		a, [death_timer]
	dec		a
	ld		[death_timer], a
	cp		0
	jp		nz, .animate_explosion
	
.reset_player
;TODO: Check for game over
	call	ResetPlayerOnDeath
	jp		.dead_update_end
	
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
  
;---------------------------------------------------
; my vblank routine - do all graphical changes here
; while the display is not drawing
;---------------------------------------------------
VBlankFunc::
	di		; disable interrupts
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
INCLUDE "Projects/PieInTheSky/SoundEffectsPlayer.asm"
INCLUDE "Projects/PieInTheSky/Player.asm"
INCLUDE "Projects/PieInTheSky/Projectiles.asm"
INCLUDE "Projects/PieInTheSky/Enemies.asm"
INCLUDE "Projects/PieInTheSky/Level.asm"
INCLUDE "Projects/PieInTheSky/Variables.asm"