; Pie in the Sky
; by Rhys Thomas
; based off examples by opus@dnai.com

; GAMEBOY SYSTEM CONSTANTS
; the hardware registers for the Game Boy begin at address $FF00
; All the 8 bit register addresses below are offsets relative to $FF00
JOYPAD_REGISTER			equ		$00		; joypad
PAD_PORT_DPAD			equ		%00100000	; select d-pad buttons
PAD_PORT_BUTTONS		equ		%00010000	; select other buttons
PAD_OUTPUT_MASK			equ		%00001111	; mask for the output buttons
DPAD_DOWN				equ		7
DPAD_UP					equ		6
DPAD_LEFT				equ		5
DPAD_RIGHT				equ		4
START_BUTTON			equ		3
SELECT_BUTTON			equ		2
B_BUTTON				equ		1
A_BUTTON				equ		0
DPAD_DOWN_MASK			equ		%10000000
DPAD_UP_MASK			equ		%01000000
DPAD_LEFT_MASK			equ		%00100000
DPAD_RIGHT_MASK			equ		%00010000
START_BUTTON_MASK		equ		%00001000
SELECT_BUTTON_MASK		equ		%00000100
B_BUTTON_MASK			equ		%00000010
A_BUTTON_MASK			equ		%00000001

DIV_REGISTER			equ		$04		; divide timer... read to get time, write to reset it to 0
TIMA_REGISTER			equ		$05		; main timer... freq is set in TAC reg, generates interupt when overflows
TMA_REGISTER			equ		$06		; Timer Modulo... main timer loaded with this value after it overflows
TAC_REGISTER			equ		$07		; Timer Control
TIMER_STOP				equ		%00000100	; timer halt flag... 0=stop, 1=run
TIMER_FREQ_MASK			equ		%00000011	; mask for timer frequency bits
TIMER_FREQ_4KHz			equ		%00000000	; main timer runs at 4.096 KHz
TIMER_FREQ_262KHz		equ		%00000001	; main timer runs at 262.144 KHz
TIMER_FREQ_65KHZ		equ		%00000010	; main timer runs at 65.536 KHz
TIMER_FREQ_16KHz		equ		%00000011	; main timer runs at 15.384 KHz

IRQ_FLAG_REGISTER		equ		$0F		; Interrupt Flag
VBLANK_INT				equ		%00000001	; bit 0 = vblank interrupt on/off
LCDC_INT				equ		%00000010	; bit 1 = LCDC interrupt on/off
TIMER_INT				equ		%00000100	; bit 2 = Timer Overflow interrupt on/off
SERIAL_INT				equ		%00001000	; bit 3 = Serial I/O Transfer Completion interrupt on/off
CONTROLLER_INT			equ		%00010000	; bit 4 = ??

LCDC_CONTROL			equ		$40		; LCD (Graphics) Control
BKG_DISP_FLAG			equ		%00000001	; bit 0 = background tile map is on if set
SPRITE_DISP_FLAG		equ		%00000010	; bit 1 = sprites are on if set
SPRITE_DISP_SIZE		equ		%00000100	; bit 2 = sprite size (0=8x8 pixels, 1=16x8)
BKG_MAP_LOC				equ		%00001000	; bit 3 = background tile map location (0=$9800-$9bff, 1=$9c00-$9fff)
TILES_LOC				equ		%00010000	; bit 4 = tile data location (0=$8800-$97ff, 1=$8000-$8fff)
WINDOW_DISP_FLAG		equ		%00100000	; bit 5 = window tile map is on if set
WINDOW_MAP_LOC			equ		%01000000	; bit 6 = window tile map location (0=$9800-$9bff, 1=$9c00-9fff)
DISPLAY_FLAG			equ		%10000000	; bit 7 = LCD display on if set

LCDC_STATUS				equ		$41		; LCDC Status
DISP_CYCLE_MODE			equ		%00000011	; mask for the display cycle mode bits
VBLANK_MODE				equ		%00000000	; system is in vertical blanking interval
HBLANK_MODE				equ		%00000001	; system is in a horizontal blanking interval
SPRITE_MODE				equ		%00000010	; system is reading sprite RAM
LCD_TRANSFER			equ		%00000011	; system is transfering data to the LCD driver

SCROLL_BKG_Y			equ		$42		; vertical scroll position of background tile map
SCROLL_BKG_X			equ		$43		; horizontal scroll position of background tile map

LCDC_LY_COUNTER			equ		$44		; increments every scan line (0..143 = display, 144-153 = vblank)
LY_COMPARE				equ		$45		; ??

DMA_REGISTER			equ		$46		; DMA Transfer and Start Address

PALETTE_BKG				equ		$47		; palette data for background tile map
PALETTE_SPRITE_0		equ		$48		; sprite palette 0 data
PALETTE_SPRITE_1		equ		$49		; sprite palette 1 data

POS_WINDOW_Y			equ		$4A		; window tile map Y position
POS_WINDOW_X			equ		$4B		; window tile map X position

INTERRUPT_ENABLE		equ		$ff		; Interrupt Enable

; $ff80 to $fffe is 128 bytes of internal RAM
STACK_TOP				equ		$fff4		; put the stack here

; video ram display locations
TILES_MEM_LOC_0			equ		$8800		; tile map tiles only
TILES_MEM_LOC_1			equ		$8000		; tile maps and sprite tiles

MAP_MEM_LOC_0			equ		$9800		; background and window tile maps
MAP_MEM_LOC_1			equ		$9c00		; (select which uses what mem loc in LCDC_CONTROL register)

SPRITE_ATTRIB_MEM_LOC	equ		$fe00		; OAM memory (sprite attributes)

; sprite attribute flags
SPRITE_FLAGS_PAL		equ		%00010000	; palette (0=sprite pal 0, 1=sprite pal 1)
SPRITE_FLAGS_XFLIP		equ		%00100000	; sprite is horizontal flipped
SPRITE_FLAGS_YFLIP		equ		%01000000	; sprite is vertical flipped
SPRITE_FLAGS_PRIORITY	equ		%10000000	; sprite display priority (0=on top bkg & win, 1=behind bkg & win)

;-------------------------------------------------------------------------
; start of the game rom (address 0000)
;-------------------------------------------------------------------------
SECTION	"ROM_Start",HOME[$0000]
  
SECTION	"VBlank_IRQ_Jump",HOME[$0040]
; Vertical Blanking interrupt
	jp	VBlankFunc

SECTION	"LCDC_IRQ_Jump",HOME[$0048]
; LCDC Status interrupt (can be set for H-Blanking interrupt)
	reti

SECTION	"Timer_Overflow_IRQ_Jump",HOME[$0050]
; Main Timer Overflow interrupt
	reti

SECTION	"Serial_IRQ_Jump",HOME[$0058]
; Serial Transfer Completion interrupt
	reti

SECTION	"Joypad_IRQ_Jump",HOME[$0060]
; Joypad Button Interrupt?????
	reti

SECTION	"GameBoy_Header_Start",HOME[$0100]
; begining of Game Boy game header
	nop
	jp 		$150         ; goto beginning of game code

; Game Boy standard header... DO NOT CHANGE!
db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
db $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
db $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

db "~Pie in the Sky~"	; game name (must be 16 bytes)
db $00,$00,$00			; unused
db $00					; cart type
db $00					; ROM Size (32 k)
db $00					; RAM Size (0 k)
db $00,$00				; maker ID
db $01					; Version     =1
db $DA					; Complement check (Important)
db $ff,$ff				; Cheksum, needs to be calculated!

; tiles are here
INCLUDE "Projects/PieInTheSky/Data/TestTiles.z80"

; map is here
INCLUDE "Projects/PieInTheSky/Data/TestMap.z80"

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

	ld		a, 0
	ld		[vblank_flag], a
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[bomb_ypos], a
	ld		[bomb_xpos], a
	
	; load the tiles
	ld		bc, TileLabel
	call	LoadTiles
	
	ld		de, TestMap
	; load the background map
	call	LoadMapToBkg

	; init the palettes
	call	InitPalettes

	; clear the sprite data
	call	InitSprites
	
	; init  my spaceship sprite
	ld		a, $40
	ld		[spaceshipL_xpos], a
	ld		[spaceshipL_ypos], a
	ld		a, 9
	ld		[spaceshipL_tile], a
	ld		a, 0
	ld		[spaceshipL_flags], a
	
	ld		a, $40
	ld		[spaceshipR_ypos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	ld		a, 10
	ld		[spaceshipR_tile], a
	ld		a, 0
	ld		[spaceshipR_flags], a
	
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
	call UpdateBulletPositions
	call UpdateBombPosition
	
	; adjust sprite due to d-pad presses
	call	MoveSpaceship
	
	; reset vblank flag
	ld		a, 0
	ld		[vblank_flag], a
	
	jp		Game_Loop


;------------------------------------------
; init the local copy of the sprites
;------------------------------------------
InitSprites::
	ld		hl, $c000	; my sprites are at $c000
	ld		b, 40*4		; 40 sprites, 4 bytes per sprite
	ld		a, $ff
.init_sprites_loop
	ld		[hli], a
	dec		b
	jr		nz, .init_sprites_loop

; init my bullet sprites
	ld		hl, bullet_data
	ld		b, 16		; 16 bullets in table
.init_bullets_loop
	ld 		a, $ff
	ld		[hli], a
	inc		hl			; 2 bytes per bullet

	dec		b
	jr		nz, .init_bullets_loop
	
	ld		hl, bomb_data
	ld 		a, $ff
	ld		[hl], a 
	
	ret

;----------------------------------------------------
; load the tiles from ROM into the tile video memory
;
; IN:	bc = address of tile data to load
;----------------------------------------------------
LoadTiles::
	ld		hl, TILES_MEM_LOC_1	; load the tiles to tiles bank 1

	ld		de, 14 * 16
	ld		d, $10  ; 16 bytes per tile
	ld		e, $0f  ; number of tiles to load

.load_tiles_loop
	; only write during
	ldh		a, [LCDC_STATUS]	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, .load_tiles_loop

	ld		a, [bc]		; get the next value from the source
	ld		[hli], a	; load the value to the destination, incrementing dest. ptr
	inc		bc			; increment the source ptr

	; now loop de times
	dec		d
	jp		nz, .load_tiles_loop
	dec		e
	jp		nz, .load_tiles_loop

	ret

;----------------------------------------------------
; load the tile map to the background
;
; IN:	bc = address of map to load
;----------------------------------------------------
LoadMapToBkg::
	ld		hl, MAP_MEM_LOC_0	; load the map to map bank 0

	ld 		c, %11111111
	
	ld 		a, 0
	ld		b, a
	ld		[CurrentMapColumnPos], a
	ld 		[CurrentBGMapScrollTileX], a
	
.load_map_loop
	ld  	a,[de]
	ld  	[hl],a
	
	inc 	de
	
	ld		a, c
	ld 		bc, %00100000
	add 	hl, bc
	ld		c, a
	
	ld		a, [CurrentMapColumnPos]
	inc		a
	ld		[CurrentMapColumnPos], a
	cp		%00100000
	jr  	nz,.go_to_map_loop
	
	ld 		a, 0
	ld		[CurrentMapColumnPos], a
	
	ld		a, [CurrentBGMapScrollTileX]
	inc		a
	ld		[CurrentBGMapScrollTileX], a
	
	ld		b, c
	ld		hl, MAP_MEM_LOC_0
	ld		a, [CurrentBGMapScrollTileX]
	ld 		c, a
	ld 		a, b
	ld		b, 0
	add		hl, bc
	ld		c, a
	
.go_to_map_loop
	dec 	bc
	ld  	a,b
	or  	c
	jr  	nz,.load_map_loop
	
.load_next_map_block
	ld 		c, %11111111
	ld 		a, 0
	ld		b, a
	
	ld		a, [CurrentMapBlock]
	inc		a
	ld		[CurrentMapBlock], a
	cp		%00000100
	jr  	nz,.load_map_loop
	
	ld		a, [CurrentMapBlock]
	dec		a
	ld		[CurrentMapBlock], a
	
	ld		a, 2
	ld		[CurrentBGMapScrollTileX], a
	
	ret

;----------------------------------------------------
; init the palettes to basic
;----------------------------------------------------
InitPalettes::
	ld		a, %10010011	; set palette colors

	; load it to all the palettes
	ldh		[PALETTE_BKG], a
	ldh		[PALETTE_SPRITE_0], a
	ldh		[PALETTE_SPRITE_1], a

	ret
  
;-----------------------------------------------------------------------
; read the joypad
;
; output:
; 		This loads two variables:
;			joypad_held		- what buttons are currently held
;			joypad_down		- what buttons went down since last joypad read
;-----------------------------------------------------------------------
ReadJoypad::
	; get the d-pad buttons
	ld		a, PAD_PORT_DPAD		; select d-pad
	ldh		[JOYPAD_REGISTER], a	; send it to the joypad
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]	; get the result back (takes a few cycles)
	cpl			; bit-flip the result
	and		PAD_OUTPUT_MASK		; mask out the output bits
	swap	a					; put the d-pad button results to top nibble
	ld		b, a				; and store it

	; get A / B / SELECT / START buttons
	ld		a, PAD_PORT_BUTTONS		; select buttons
	ldh		[JOYPAD_REGISTER], a	; send it to the joypad
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]	; get the result back (takes even more cycles?)
	cpl			; bit-flip the result
	and		PAD_OUTPUT_MASK		; mask out the output bits
	or		b					; add it to the other button bits
	ld		b, a			; put it back in c

	; calculate the buttons that went down since last joypad read
	ld		a, [joypad_held]	; grab last button bits
	cpl							; invert them
	and		b					; combine the bits with current bits
	ld		[joypad_down], a	; store just-went-down button bits

	ld		a, b
	ld      [joypad_held], a	; store the held down button bits

	ld		a, $30       ; reset joypad
    ldh		[JOYPAD_REGISTER],A

	ret			; done

;---------------------------------------------------
; my vblank routine - do all graphical changes here
; while the display is not drawing
;---------------------------------------------------
VBlankFunc::
	di		; disable interrupts
	push	af
	
	; increment my little timer
	ld		a, [ScrollTimer]			; get the scroll timer
	inc		a					; increment it
	ld		[ScrollTimer], a

	; is it time to scroll yet?
	and		%00000111
	jr		nz, .vblank_sprite_DMA
	
	ld		a, [CurrentMapBlock]
	ld		c, a
	ld		a,	TestMapBlockTotal
	cp		c
	jr		z, .vblank_sprite_DMA
	
	ld 		a, [PixelsScrolled]
	inc 	a
	ld 		[PixelsScrolled], a
	
	and		%00000111				;increment tiles scrolled every 8 pixels
	jr		nz, .vblank_do_scroll
	
	call HandleColumnLoad

.vblank_do_scroll
	; do a background screen scroll
	ldh		a, [SCROLL_BKG_X]		; scroll the background horiz one bit
	inc		a
	ldh		[SCROLL_BKG_X], a

.resolve_scroll_collisions
	call FindShipTileIndexes
	
	inc 	hl
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .vblank_sprite_DMA
	
.MoveShipBackLeft
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
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

;---------------------------------------------------
; Handle screen scroll and load here
;---------------------------------------------------
HandleColumnLoad::
	ld 		a, 0
	ld 		[PixelsScrolled], a
	
	ld 		a, [TotalTilesScrolled]
	inc 	a
	ld 		[TotalTilesScrolled], a
	
	cp		%00001000	;reset count if a = 8
	jr		nz, .track_screen_scroll
	
	ld		a, [CurrentMapBlock]
	inc 	a
	ld		[CurrentMapBlock], a
	
	ld 		a, 0
	ld 		[TotalTilesScrolled], a
	
.track_screen_scroll
	ld 		a, [CurrentBGMapScrollTileX]
	inc 	a
	ld 		[CurrentBGMapScrollTileX], a
	
	cp		%00001010	;reset count if a = 10 = -22 + 32
	jr		nz, .track_window_scroll
	
	ld 		a, 0
	sub 	%00010110 ;22
	ld 		[CurrentBGMapScrollTileX], a

.track_window_scroll
	ld 		a, [CurrentWindowTileX]
	inc 	a
	ld 		[CurrentWindowTileX], a
	
	cp		%00100000	;reset count if a = 32
	jr		nz, .get_map_start_point
	
	ld 		a, 0
	ld 		[CurrentWindowTileX], a
	
.get_map_start_point
	ld		hl, TestMap	; load the map to map bank 0
	
	ld		b, 0
	ld		c, %00100000
	ld		a, [TotalTilesScrolled]
	
.get_map_start_loop
	cp		0
	jr 		z, .get_map_block_loop_start
	add		hl, bc
	dec		a
	jr		.get_map_start_loop
	
.get_map_block_loop_start
	ld		bc, %100000000
	ld		a, [CurrentMapBlock]
	
.get_map_block_loop
	cp		0
	jr 		z, .load_next_map_column
	add		hl, bc
	dec		a
	jr		.get_map_block_loop
	
.load_next_map_column
	ld		de, MAP_MEM_LOC_0
	ld 		a, [CurrentBGMapScrollTileX]
	add		a, %00010110 ;22
	ld		c, a
	ld		a, e
	add		a, c
	ld		e, a
	
	ld 		c, %00100000
	
.load_next_column_loop
	ld		a, [hl]
	ld		[de], a
	
	inc 	hl
	
	ld 		a, c
	
	ld		b, h
	ld		c, l
	ld		h, d
	ld		l, e 			;store hl -> bc, de -> hl
	ld		de, %00100000	
	add		hl, de			;add 32 to hl (current address of bg map)
	ld		d, h
	ld		e, l
	ld 		h, b
	ld 		l, c			;store hl -> de, bc -> hl
	
	ld		b, 0
	ld 		c, a
	
	dec		c
	ld		a, b
	or 		c
	jr		nz, .load_next_column_loop
	
	ret

;-------------------------------------------------------------
; adjust my spaceship sprite based on d-pad presses.  This
; both moves the sprite and chooses the sprite attributes to
; make the sprite face the correct direction
;-------------------------------------------------------------
MoveSpaceship::
	push	af
	
	; check buttons for d-pad presses
.check_for_up
	ld		a, [joypad_held]
	bit		DPAD_UP, a
	jp		z, .check_for_down	; if button not pressed then done

	; up was held down
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .check_for_left

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		16
	jp 		z, .check_for_left
	
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a

	call FindShipTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackDown

	inc		hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackDown

	inc		hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .check_for_left
	
.MoveShipBackDown
	ld		a, [spaceshipL_ypos]
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	; don't check down, since up + down should never occur
	jp		.check_for_left

.check_for_down
	ld		a, [joypad_held]
	bit		DPAD_DOWN, a
	jp		z, .check_for_left	; if button not pressed then done

	; down was held down
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .check_for_left

	; move sprite up a pixel
	ld		a, [spaceshipL_ypos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
	call FindShipTileIndexes
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackUp
	
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .check_for_left
	
.MoveShipBackUp
	ld		a, [spaceshipL_ypos]
	dec		a
	ld		[spaceshipL_ypos], a
	ld		[spaceshipR_ypos], a
	
.check_for_left
	ld		a, [joypad_held]
	bit		DPAD_LEFT, a
	jp		z, .check_for_right	; if button not pressed then done

	; left was pressed
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .done_checking_dpad

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		8
	jp 		z, .done_checking_dpad
	
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	call FindShipTileIndexes
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackRight
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .done_checking_dpad
	
.MoveShipBackRight
	ld		a, [spaceshipL_xpos]
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
	jp		.done_checking_dpad	; if left was pressed, don't check right

.check_for_right
	ld		a, [joypad_held]
	bit		DPAD_RIGHT, a
	jp		z, .done_checking_dpad	; if button not pressed then done

	; right was pressed
	ld		a, [ScrollTimer]	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, .done_checking_dpad

	; move sprite left one pixel
	ld		a, [spaceshipL_xpos]
	
	cp 		152
	jp 		z, .check_for_left
	
	inc		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a

	call FindShipTileIndexes
	
	inc 	hl
	inc 	hl
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		nz, .MoveShipBackLeft
	
	ld		a, 0
	ld		b, a
	ld		a, 32
	ld		c, a
	add		hl, bc
	
	ld		a, [hl] ;Tile ship is on stored at hl
	cp		11
	jr		z, .done_checking_dpad
	
.MoveShipBackLeft
	ld		a, [spaceshipL_xpos]
	dec		a
	ld		[spaceshipL_xpos], a
	add		a, 8
	ld		[spaceshipR_xpos], a
	
.done_checking_dpad
	ld		a, [joypad_down]
	bit		A_BUTTON, a
	jp		z, .check_for_bomb
	
	call	LaunchBullet
	
.check_for_bomb
	ld		a, [joypad_down]
	bit		B_BUTTON, a
	jp		z, .did_not_fire
	
	call	LaunchBomb

.did_not_fire
	pop		af
	ret

;-----------------------------------------------------------------
; detect collisions between the ship and the environment
; B = xBottomLeftShipTileIndex, C = yBottomLeftShipTileIndex
;-----------------------------------------------------------------
FindShipTileIndexes::
	ld 		a, [spaceshipL_xpos]
	sub		8
	ld		b, -1
	
.XSubLoop
	jr		c, .StartYLoop
	sub		8
	inc 	b
	jp		.XSubLoop

.StartYLoop
	ld 		a, [spaceshipL_ypos]
	sub		8
	ld		c, -2
	
.YSubLoop
	jr		c, .EndTileIndexLoops
	sub		8
	inc 	c
	jp		.YSubLoop
	
.EndTileIndexLoops
	ld		a, 0
	ld		h, a
	ld 		a, [CurrentWindowTileX]
	add		b
	
	cp		32
	jr		c, .StoreStartAndMapWidth
	
	sub 	32
	
.StoreStartAndMapWidth
	ld		l, a
	
	ld		a, 0
	ld		d, a
	ld		a, 32
	ld		e, a
	
	ld 		a, c
	
.GetTileIndexLoop
	add		hl, de
	dec		a
	jr		nz, .GetTileIndexLoop
	
	ld		d, h
	ld		e, l
	ld		hl, MAP_MEM_LOC_0
	add 	hl, de ;HL now contains the address of the tile at the bottom left ship co-ordinate
	
	ret
	
;------------------------------------------------------------
; launch a bullet
;------------------------------------------------------------
LaunchBullet::
	push	af
	push	bc
	push	de

	; find an empty bullet
	ld		hl, bullet_data		; get the addr of the 1st bullet
	ld		d, 16				; 16 bullet slots to check
.find_empty_bullet_loop
	ld		a, [hl]
	cp		$ff			; is this bullet unused
	jr		z, .found_empty_bullet

	inc		hl	; skip 2 bytes, to top of next bullet
	inc		hl

	dec		d
	jr		nz, .find_empty_bullet_loop

	; no slots left... exit
	pop		de
	pop		bc
	pop		af
	ret

.found_empty_bullet
	; calc bullet x launch pos
	ld		a, [spaceshipR_xpos]
	add     a, 8
	ld		b, a
	; calc bullet y launch pos
	ld		a, [spaceshipR_ypos]
	add		a, 2
	ld		c, a
	; direction is right
	ld		a, 2
	
	; a = orientation
	; b = x pos
	; c = y pos
	; hl = bullet data to launch
	; index into bullet array = 16 - d

	ld		[hli], a	; store the orientation
	ld		[hl], 60	; bullet lasts 1 second (60 vblanks)

	ld		a, 16
	sub		d		; a = index into bullet array

	ld		hl, bullet_sprites	; get top of bullet sprites

	sla		a
	sla		a		; multiply index by 4 (4 bytes per sprite)
	ld		e, a	; store it in de
	ld		d, 0

	add		hl, de	; I should be pointing at the correct sprite addr

	; load the sprite info
	ld		[hl], c
	inc		hl
	ld		[hl], b
	inc		hl
	ld		[hl], 12	; bullets use tile 12
	inc		hl
	ld		[hl], 0

	pop		de
	pop		bc
	pop		af
	ret
	
;------------------------------------------------------------
; launch a bomb
;------------------------------------------------------------
LaunchBomb::
	ld		hl, bomb_data
	ld		a, [hl]
	cp		$ff			; is this bomb unused
	jr 		nz, .exit_bomb_launch
	
	ld		a, 1
	ld		[hli], a	; store the x speed
	ld		[hl], 60	; bomb lasts 1 second (60 vblanks)
	
	; calc bomb x launch pos
	ld		a, [spaceshipR_xpos]
	add     a, 8
	ld		[bomb_xpos], a
	
	; calc bomb y launch pos
	ld		a, [spaceshipR_ypos]
	add		a, 2
	ld		[bomb_ypos], a
	
	; load the sprite info
	ld		a, 13
	ld		[bomb_sprite], a	; bombs use tile 13
	ld		a, 0
	ld		[bomb_flags], a
	
.exit_bomb_launch
	ret
	
;-----------------------------------------------------------------
; update the bullet timing ever vblank
;-----------------------------------------------------------------
UpdateBulletTimers::
	push	af
	push	bc
	push	hl

	ld		hl, bullet_data
	ld		b, 16		; 16 bullets to update
.update_bullets_loop
	ld		a, [hli]
	cp		$ff
	jr		z, .update_bullets_loop_end

	; this is an active bullet
	dec		[hl]	; decrement the timer
	jr		nz, .update_bullets_loop_end

	; this bullet's timer ran out
	push	hl		; save where we were
	push	bc

	dec		hl		; go back a byte
	ld		a, $ff
	ld		[hl], a	; this sprite is no longer active

	; calc this bullet's sprite location
	ld		a, 16	; calc index (16 - b)
	sub		b
	ld		e, a	; store index in de
	sla		e
	sla		e		; 4 bytes per sprite attrib
	ld		d, 0
	ld		hl, bullet_sprites
	add		hl, de

	ld		a, $00
	ld		[hli], a
	ld		[hl], a		; turn of the sprite in the attrib table
	pop		bc
	pop		hl

.update_bullets_loop_end
	inc		hl
	dec		b
	jr		nz, .update_bullets_loop

	pop		hl
	pop		bc
	pop		af
	ret

;-----------------------------------------------------------------
; update the bomb timing ever vblank
;-----------------------------------------------------------------
UpdateBombTimer::
	ld		hl, bomb_data
	ld		a, [hli]
	cp		$ff
	jr		z, .update_bomb_end
	
	; bomb is active
	dec		[hl]	; decrement the timer
	jr		nz, .update_bomb_end

	dec 	hl
	ld		a, $ff
	ld		[hl], a
	
	ld		a, $00
	ld		[bomb_ypos], a
	ld		[bomb_xpos], a		; turn off the sprite in the attrib table
	
.update_bomb_end
	ret
	
;------------------------------------------------------
; update bullet positions
;------------------------------------------------------
UpdateBulletPositions::
	push	af
	push	bc

	ld		hl, bullet_data
	ld		b, 16		; 16 bullets to update
.update_bullets_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_bullets_pos_loop_end

	; this is an active bullet
	; get its sprite addr
	push	hl
	ld		a, 16	; calc index (16 - b)
	sub		b
	ld		e, a	; store index in de
	sla		e
	sla		e		; 4 bytes per sprite attrib
	ld		d, 0
	ld		hl, bullet_sprites
	add		hl, de
	ld		d, h
	ld		e, l	; store the address in de
	pop		hl

.bullet_fly_right
	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, [hl]
	add		a, 2
	ld		[hl], a
	pop		hl

.update_bullets_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, .update_bullets_pos_loop

	pop		bc
	pop		af
	ret

;------------------------------------------------------
; update bomb position
;------------------------------------------------------
UpdateBombPosition::
	ld		hl, bomb_data
	ld		a, [hl]
	cp		$ff
	jp		z, .update_bomb_pos_end
	
	ld		a, [bomb_xpos]
	add		a, 2
	ld		[bomb_xpos], a
	
.update_bomb_pos_end
	ret

;-------------------------------------------------------------------------
; Internal RAM... store dynamic data here
;-------------------------------------------------------------------------
SECTION	"RAM_Start_Sprites",BSS[$c000]
; local version of sprite attrib table
spaceshipL_ypos:
ds		1
spaceshipL_xpos:
ds		1
spaceshipL_tile:
ds		1
spaceshipL_flags:
ds		1

spaceshipR_ypos:
ds		1
spaceshipR_xpos:
ds		1
spaceshipR_tile:
ds		1
spaceshipR_flags:
ds		1

bomb_ypos:
ds		1
bomb_xpos:
ds		1
bomb_sprite:
ds		1
bomb_flags:
ds		1

; bullet sprites start here (16 of them)
bullet_sprites:
ds		1

SECTION	"RAM_Other_Variables",BSS[$c0A0]

; frame timing
vblank_flag:
ds		1		; set if a vblank occured since last pass through game loop

; joypad values
joypad_held:
ds		1		; what buttons are currently held
joypad_down:
ds		1		; what buttons went down since last joypad read

bullet_data:
ds		32

bomb_data:
ds		2

; temp variables
ScrollTimer:
ds		1		; temp variable for slowing down scroll speed

PixelsScrolled:
ds		1;
TotalTilesScrolled:
ds		1;
CurrentBGMapScrollTileX:
ds		1;
CurrentWindowTileX:
ds		1;
CurrentMapColumnPos:
ds		1;
CurrentMapBlock:
ds		1;


