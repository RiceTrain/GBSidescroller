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

	call 	InitWorkingVariables
	call 	InitLevel
	call	InitSprites
	call 	InitPlayerSprite
	
	; set display to on, background on, window off, sprites off, sprite size 8x8
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

	; get this frame's joypad info
	call	ReadJoypad

	; update any active bullets
	; do this before MoveSpaceship, since we want the bullet to display at
	; its launch position for one frame
	call 	UpdateBulletPositions
	call 	UpdateBombPosition
	call 	UpdateEnemyBehaviours
	
	; adjust sprite due to d-pad presses
	call	MoveSpaceship
	
	; reset vblank flag
	ld		a, 0
	ld		[vblank_flag], a
	
	jp		Game_Loop

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
	di		; disable interrupts
	push	af
	
	call ScrollLevel
	
; load the sprite attrib table to OAM memory
.vblank_sprite_DMA
	ld		a, $c0				; dma from $c000 (where I have my local copy of the attrib table)
	ldh		[DMA_REGISTER], a	; start the dma

	ld		a, $28		; wait for 160 microsec (using a loop)
.vblank_dma_wait
	dec		a
	jr		nz, .vblank_dma_wait

	ld		hl, SPRITE_ATTRIB_MEM_LOC

	; set the vblank occured flag
	ld		a, 1
	ld		[vblank_flag], a
	
	call UpdateBulletTimers
	call UpdateBombTimer
	
	pop af
	ei		; enable interrupts
	reti	; and done

INCLUDE "Projects/PieInTheSky/Variables.asm"