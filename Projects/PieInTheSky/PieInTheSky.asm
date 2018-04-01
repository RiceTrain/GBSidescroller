; Pie in the Sky
; by Rhys Thomas
; based off examples by opus@dnai.com

INCLUDE "Projects/PieInTheSky/Constants.asm"

SECTION	"Game_Code_Start",HOME[$0150]
; begining of game code
start::
	; init the stack pointer
	ld		sp, STACK_TOP

	; enable only vblank interrupts
	ld		a, VBLANK_INT			; set vblank interrupt bit
	ldh		[INTERRUPT_ENABLE], a	; load it to the hardware register

	; standard inits
	sub		a	;	a = 0
	ldh		[LCDC_STATUS], a	; init status
	ldh		[LCDC_CONTROL], a	; init LCD to everything off
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a

	call	InitLevelStart
	
	; set display to on, background on, window off, sprites on, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG | BKG_DISP_FLAG | SPRITE_DISP_FLAG | TILES_LOC | WINDOW_MAP_LOC
	ldh		[LCDC_CONTROL],a

	; allow interrupts to start occuring
	ei

; main game loop
Game_Loop::
	; don't do a frame update unless we have had a vblank
	ld		a, [vblank_flag]
	cp		0
	jp		z, Game_Loop

	ld		a, [alive]
	cp 		1
	jr		z, .do_main_update

	call 	Player_Dead_Update
	jp		.reset_vblank_flag
	
.do_main_update
	call 	Main_Game
	
.reset_vblank_flag
	; reset vblank flag
	ld		a, 0
	ld		[vblank_flag], a
	
	jp		Game_Loop

Main_Game::
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
	call	InitPlayerData
	
	ld		a, 76
	ld		[checkpoint_ship_y], a
	ld		a, 80
	ld		[checkpoint_ship_x], a
	call 	InitPlayerSprite
	
	ret
	
Player_Dead_Update::
	ld		a, [death_timer]
	dec		a
	ld		[death_timer], a
	cp		0
	jp		nz, .dead_update_end
	
.reset_player
;TODO: Check for game over
	call	ResetPlayerOnDeath
	
.dead_update_end
	ret
	
ResetPlayerOnDeath::
	call 	InitWorkingVariables
	
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	ld		hl, TestMap
	call	LoadMapToBkg
	
	call	InitSprites
	call	InitPlayerData
	call 	InitPlayerSprite
	
	ret
	
INCLUDE "Projects/PieInTheSky/Hardware.asm"
INCLUDE "Projects/PieInTheSky/Player.asm"
INCLUDE "Projects/PieInTheSky/Projectiles.asm"
INCLUDE "Projects/PieInTheSky/Enemies.asm"
INCLUDE "Projects/PieInTheSky/Level.asm"

;---------------------------------------------------
; my vblank routine - do all graphical changes here
; while the display is not drawing
;---------------------------------------------------
VBlankFunc::
;	di		; disable interrupts
;	push	af
	
; load the sprite attrib table to OAM memory
.vblank_sprite_DMA
	ld		a, $c0				; dma from $c000 (where I have my local copy of the attrib table)
	ldh		[DMA_REGISTER], a	; start the dma

	ld		a, $28		; wait for 160 microsec (using a loop)
.vblank_dma_wait
	dec		a
	jr		nz, .vblank_dma_wait

	; set the vblank occured flag
	ld		a, 1
	ld		[vblank_flag], a
	
;	pop af
;	ei		; enable interrupts
	reti	; and done

INCLUDE "Projects/PieInTheSky/Variables.asm"