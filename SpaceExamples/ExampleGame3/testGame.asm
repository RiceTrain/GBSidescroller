; Game Boy test
; © 2000 Doug Lanford
; opus@dnai.com

;---------------------------------------------------------------------
; this version of the test does the following:
;		1) sets up the gameboy
;		2) runs a scrolling background
;		3) drives a directional spaceship sprite from the joypad
;			- sprite tile and flip changes so ship is pointing in the direction of the joypad
;		4) defines and uses a bullet sprite system, which the ship can fire
;---------------------------------------------------------------------


; GAMEBOY SYSTEM CONSTANTS
; the hardware registers for the Game Boy begin at address $FF00
; All the 8 bit register addresses below are offsets relative to $FF00
#define		JOYPAD_REGISTER			$00		; joypad
#define			PAD_PORT_DPAD		%00100000	; select d-pad buttons
#define			PAD_PORT_BUTTONS	%00010000	; select other buttons
#define			PAD_OUTPUT_MASK		%00001111	; mask for the output buttons
#define			DPAD_DOWN			7
#define			DPAD_UP				6
#define			DPAD_LEFT			5
#define			DPAD_RIGHT			4
#define			START_BUTTON		3
#define			SELECT_BUTTON		2
#define			B_BUTTON			1
#define			A_BUTTON			0
#define			DPAD_DOWN_MASK		%10000000
#define			DPAD_UP_MASK		%01000000
#define			DPAD_LEFT_MASK		%00100000
#define			DPAD_RIGHT_MASK		%00010000
#define			START_BUTTON_MASK	%00001000
#define			SELECT_BUTTON_MASK	%00000100
#define			B_BUTTON_MASK		%00000010
#define			A_BUTTON_MASK		%00000001

#define		DIV_REGISTER			$04		; divide timer... read to get time, write to reset it to 0
#define		TIMA_REGISTER			$05		; main timer... freq is set in TAC reg, generates interupt when overflows
#define		TMA_REGISTER			$06		; Timer Modulo... main timer loaded with this value after it overflows
#define		TAC_REGISTER			$07		; Timer Control
#define			TIMER_STOP			%00000100	; timer halt flag... 0=stop, 1=run
#define			TIMER_FREQ_MASK		%00000011	; mask for timer frequency bits
#define			  TIMER_FREQ_4KHz	%00000000	; main timer runs at 4.096 KHz
#define			  TIMER_FREQ_262KHz	%00000001	; main timer runs at 262.144 KHz
#define			  TIMER_FREQ_65KHZ	%00000010	; main timer runs at 65.536 KHz
#define			  TIMER_FREQ_16KHz	%00000011	; main timer runs at 15.384 KHz

#define		IRQ_FLAG_REGISTER		$0F		; Interrupt Flag
#define			VBLANK_INT			%00000001	; bit 0 = vblank interrupt on/off
#define			LCDC_INT			%00000010	; bit 1 = LCDC interrupt on/off
#define			TIMER_INT			%00000100	; bit 2 = Timer Overflow interrupt on/off
#define			SERIAL_INT			%00001000	; bit 3 = Serial I/O Transfer Completion interrupt on/off
#define			CONTROLLER_INT		%00010000	; bit 4 = ??

#define		LCDC_CONTROL			$40		; LCD (Graphics) Control
#define			BKG_DISP_FLAG		%00000001	; bit 0 = background tile map is on if set
#define         SPRITE_DISP_FLAG	%00000010	; bit 1 = sprites are on if set
#define			SPRITE_DISP_SIZE	%00000100	; bit 2 = sprite size (0=8x8 pixels, 1=16x8)
#define			BKG_MAP_LOC			%00001000	; bit 3 = background tile map location (0=$9800-$9bff, 1=$9c00-$9fff)
#define			TILES_LOC			%00010000	; bit 4 = tile data location (0=$8800-$97ff, 1=$8000-$8fff)
#define			WINDOW_DISP_FLAG	%00100000	; bit 5 = window tile map is on if set
#define			WINDOW_MAP_LOC		$01000000	; bit 6 = window tile map location (0=$9800-$9bff, 1=$9c00-9fff)
#define			DISPLAY_FLAG		%10000000	; bit 7 = LCD display on if set
#define		LCDC_STATUS				$41		; LCDC Status
#define			DISP_CYCLE_MODE		%00000011	; mask for the display cycle mode bits
#define			  VBLANK_MODE		%00000000	; system is in vertical blanking interval
#define			  HBLANK_MODE		%00000001	; system is in a horizontal blanking interval
#define			  SPRITE_MODE		%00000010	; system is reading sprite RAM
#define			  LCD_TRANSFER		%00000011	; system is transfering data to the LCD driver

#define		SCROLL_BKG_Y			$42		; vertical scroll position of background tile map
#define		SCROLL_BKG_X			$43		; horizontal scroll position of background tile map

#define		LCDC_LY_COUNTER			$44		; increments every scan line (0..143 = display, 144-153 = vblank)
#define		LY_COMPARE				$45		; ??

#define		DMA_REGISTER			$46		; DMA Transfer and Start Address

#define		PALETTE_BKG				$47		; palette data for background tile map
#define		PALETTE_SPRITE_0		$48		; sprite palette 0 data
#define		PALETTE_SPRITE_1		$49		; sprite palette 1 data

#define		POS_WINDOW_Y			$4A		; window tile map Y position
#define		POS_WINDOW_X			$4B		; window tile map X position

#define		INTERRUPT_ENABLE		$ff		; Interrupt Enable

; $ff80 to $fffe is 128 bytes of internal RAM
#define		STACK_TOP				$fff4		; put the stack here

; video ram display locations
#define		TILES_MEM_LOC_0			$8800		; tile map tiles only
#define		TILES_MEM_LOC_1			$8000		; tile maps and sprite tiles

#define		MAP_MEM_LOC_0			$9800		; background and window tile maps
#define		MAP_MEM_LOC_1			$9c00		; (select which uses what mem loc in LCDC_CONTROL register)

#define		SPRITE_ATTRIB_MEM_LOC	$fe00		; OAM memory (sprite attributes)

; sprite attribute flags
#define		SPRITE_FLAGS_PAL		%00010000	; palette (0=sprite pal 0, 1=sprite pal 1)
#define		SPRITE_FLAGS_XFLIP		%00100000	; sprite is horizontal flipped
#define		SPRITE_FLAGS_YFLIP		%01000000	; sprite is vertical flipped
#define		SPRITE_FLAGS_PRIORITY	$10000000	; sprite display priority (0=on top bkg & win, 1=behind bkg & win)



;-------------------------------------------------------------------------
; start of the game rom (address 0000)
;-------------------------------------------------------------------------
.org $0000

; NOTE: the hardware requires the interrupt jumps to be at these addresses

.org $0040
; Vertical Blanking interrupt
	jp	VBlankFunc

.org $0048
; LCDC Status interrupt (can be set for H-Blanking interrupt)
	reti

.org $0050
; Main Timer Overflow interrupt
	reti

.org $0058
; Serial Transfer Completion interrupt
	reti

.org $0060
; Joypad Button Interrupt?????
	reti




.org $0100
; begining of Game Boy game header
	nop
	jp 		$150         ; goto beginning of game code

; Game Boy standard header... DO NOT CHANGE!
.db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
.db $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
.db $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

.db "Opus Test       "	; game name (must be 16 bytes)
.db $00,$00,$00			; unused
.db $00					; cart type
.db $00					; ROM Size (32 k)
.db $00					; RAM Size (0 k)
.db $00,$00				; maker ID
.db $01					; Version     =1
.db $DA					; Complement check (Important)
.db $ff,$ff				; Cheksum, needs to be calculated!



.org $0150
; begining of game code
start
	; init the stack pointer
	ld		sp, STACK_TOP

	; enable only vblank interrupts
	ld		a, VBLANK_INT			; set vblank interrupt bit
	ldh		(INTERRUPT_ENABLE), a	; load it to the hardware register

	; standard inits
	sub		a	;	a = 0
	ldh		(LCDC_STATUS), a	; init status
	ldh		(LCDC_CONTROL), a	; init LCD to everything off
	ldh		(SCROLL_BKG_X), a	; background map will start at 0,0
	ldh		(SCROLL_BKG_Y), a

	ld		a, 0
	ld		(vblank_flag), a

	; load the tiles
	ld		bc, TileData
	call	LoadTiles

	; load the background map
	ld		bc, BkgMapData
	call	LoadMapToBkg

	; init the palettes
	call	InitPalettes

	; clear the sprite data
	call	InitSprites

	; init  my spaceship sprite
	ld		a, $40
	ld		(spaceship_xpos), a
	ld		(spaceship_ypos), a
	ld		a, 2
	ld		(spaceship_tile), a
	ld		a, 0
	ld		(spaceship_flags), a

	; set display to on, background on, window off, sprites on, sprite size 8x8
	;	tiles at $8000, background map at $9800, window map at $9C00
	ld		a, DISPLAY_FLAG + BKG_DISP_FLAG + SPRITE_DISP_FLAG + TILES_LOC + WINDOW_MAP_LOC
	ldh		(LCDC_CONTROL),a

	; allow interrupts to start occuring
	ei

; main game loop
Game_Loop
	; don't do a frame update unless we have had a vblank
	ld		a, (vblank_flag)
	cp		0
	jp		z, end_game_loop

	; get this frame's joypad info
	call	ReadJoypad

	; update any active bullets
	; do this before MoveSpaceship, since we want the bullet to display at
	; its launch position for one frame
	call	UpdateBulletPositions

	; adjust sprite due to d-pad presses
	call	MoveSpaceship

	; reset vblank flag
	ld		a, 0
	ld		(vblank_flag), a

end_game_loop
; time to loop!
	jp		Game_Loop




;------------------------------------------
; init the local copy of the sprites
;------------------------------------------
InitSprites
	ld		hl, $c000	; my sprites are at $c000
	ld		b, 40*4		; 40 sprites, 4 bytes per sprite
	ld		a, $ff
init_sprites_loop
	ld		(hli), a
	dec		b
	jr		nz, init_sprites_loop

; init my bullet sprites
	ld		hl, bullet_data
	ld		b, 16		; 16 bullets in table
init_bullets_loop
	ld		a, $ff		; signal for an unused bullet slot
	ld		(hli), a
	inc		hl			; 2 bytes per bullet

	dec		b
	jr		nz, init_bullets_loop

	ret


;----------------------------------------------------
; load the tiles from ROM into the tile video memory
;
; IN:	bc = address of tile data to load
;----------------------------------------------------
LoadTiles
	ld		hl, TILES_MEM_LOC_1	; load the tiles to tiles bank 1

	ld		de, 4 * 16
	ld		d, $10  ; 16 bytes per tile
	ld		e, $05  ; number of tiles to load

load_tiles_loop
	; only write during
	ldh		a, (LCDC_STATUS)	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, load_tiles_loop

	ld		a, (bc)		; get the next value from the source
	ld		(hli), a	; load the value to the destination, incrementing dest. ptr
	inc		bc			; increment the source ptr

	; now loop de times
	dec		d
	jp		nz, load_tiles_loop
	dec		e
	jp		nz, load_tiles_loop

	ret



;----------------------------------------------------
; load the tile map to the background
;
; IN:	bc = address of map to load
;----------------------------------------------------
LoadMapToBkg
	ld		hl, MAP_MEM_LOC_0	; load the map to map bank 0

	ld		d, $00	; 256 bytes per "block"
	ld		e, $04	; 4 blocks (32x32 tiles, 1024 bytes)

load_map_loop
	; only write during
	ldh		a, (LCDC_STATUS)	; get the status
	and		SPRITE_MODE			; don't write during sprite and transfer modes
	jr		nz, load_map_loop

	ld		a, (bc)		; get the next value from the source
	ld		(hli), a	; load the value to the destination, incrementing dest. ptr
	inc		bc			; increment the source ptr

	; now loop de times
	dec		d
	jp		nz, load_map_loop
	dec		e
	jp		nz, load_map_loop

	ret




;----------------------------------------------------
; init the palettes to basic
;----------------------------------------------------
InitPalettes
	ld		a, %10010011	; set palette colors

	; load it to all the palettes
	ldh		(PALETTE_BKG), a
	ldh		(PALETTE_SPRITE_0), a
	ldh		(PALETTE_SPRITE_1), a

	ret



;-----------------------------------------------------------------------
; read the joypad
;
; output:
; 		This loads two variables:
;			joypad_held		- what buttons are currently held
;			joypad_down		- what buttons went down since last joypad read
;-----------------------------------------------------------------------
ReadJoypad
	; get the d-pad buttons
	ld		a, PAD_PORT_DPAD		; select d-pad
	ldh		(JOYPAD_REGISTER), a	; send it to the joypad
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)	; get the result back (takes a few cycles)
	cpl			; bit-flip the result
;  ld	b, a
	and		PAD_OUTPUT_MASK		; mask out the output bits
	swap	a					; put the d-pad button results to top nibble
	ld		b, a				; and store it

	; get A / B / SELECT / START buttons
	ld		a, PAD_PORT_BUTTONS		; select buttons
	ldh		(JOYPAD_REGISTER), a	; send it to the joypad
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)
	ldh		a, (JOYPAD_REGISTER)	; get the result back (takes even more cycles?)
	cpl			; bit-flip the result
	and		PAD_OUTPUT_MASK		; mask out the output bits
	or		b					; add it to the other button bits
	ld		b, a			; put it back in c

	; calculate the buttons that went down since last joypad read
	ld		a, (joypad_held)	; grab last button bits
	cpl							; invert them
	and		b					; combine the bits with current bits
	ld		(joypad_down), a	; store just-went-down button bits

	ld		a, b
	ld      (joypad_held), a	; store the held down button bits

	ld		a, $30       ; reset joypad
    ldh		(JOYPAD_REGISTER),A

	ret			; done




;---------------------------------------------------
; my vblank routine - do all graphical changes here
; while the display is not drawing
;---------------------------------------------------
VBlankFunc
	di		; disable interrupts
	push	af

	; increment my little timer
	ld		a, (ScrollTimer)			; get the scroll timer
	inc		a					; increment it
	ld		(ScrollTimer), a

	; is it time to scroll yet?
	and		%00000111
	jr		nz, vblank_sprite_DMA

vblank_do_scroll
	; do a background screen scroll
	ldh		a, (SCROLL_BKG_X)		; scroll the background horiz one bit
	inc		a
	ldh		(SCROLL_BKG_X), a

; load the sprite attrib table to OAM memory
vblank_sprite_DMA
	ld		a, $c0				; dma from $c000 (where I have my local copy of the attrib table)
	ldh		(DMA_REGISTER), a	; start the dma

	ld		a, 28h		; wait for 160 microsec (using a loop)
vblank_dma_wait
	dec		a
	jr		nz, vblank_dma_wait

	ld		hl, SPRITE_ATTRIB_MEM_LOC

	; set the vblank occured flag
	ld		a, 1
	ld		(vblank_flag), a

	call	UpdateBulletTimers

	pop af
	ei		; enable interrupts
	reti	; and done



;-------------------------------------------------------------
; adjust my spaceship sprite based on d-pad presses.  This
; both moves the sprite and chooses the sprite attributes to
; make the sprite face the correct direction
;-------------------------------------------------------------
MoveSpaceship
	push	af

	; check buttons for d-pad presses
check_for_up
	ld		a, (joypad_held)
	bit		DPAD_UP, a
	jp		z, check_for_down	; if button not pressed then done

	; up was held down
check_for_upright
	; is right also held?
	ld		a, (joypad_held)
	bit		DPAD_RIGHT, a
	jp		z, check_for_upleft

	; up + right held, so sprite needs to be diagonal
	ld		a, 1				; diagonal sprite is tile 1
	ld		(spaceship_tile), a
	ld		a, 0				; flags are no x or y flip
	ld		(spaceship_flags), a

	jp		adjust_up_pos

check_for_upleft
	; is left also held?
	ld		a, (joypad_held)
	bit		DPAD_LEFT, a
	jp		z, set_up_only

	; up + left held, so sprite needs to be diagonal
	ld		a, 1				; diagonal sprite is tile 1
	ld		(spaceship_tile), a
	ld		a, SPRITE_FLAGS_XFLIP	; sprite should be x flipped
	ld		(spaceship_flags), a

	jp		adjust_up_pos

set_up_only
	; only up was held, so sprite needs to be up
	ld		a, 0	; vertical sprite is tile 0
	ld		(spaceship_tile), a
	ld		a, 0
	ld		(spaceship_flags), a

adjust_up_pos
	; adjust the sprite's position
	ld		a, (ScrollTimer)	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, check_for_left

	; move sprite up a pixel
	ld		a, (spaceship_ypos)
	dec		a
	ld		(spaceship_ypos), a

	; don't check down, since up + down should never occur
	jp		check_for_left

check_for_down
	ld		a, (joypad_held)
	bit		DPAD_DOWN, a
	jp		z, check_for_left	; if button not pressed then done

	; down was held down
check_for_downright
	; is right also held?
	ld		a, (joypad_held)
	bit		DPAD_RIGHT, a
	jp		z, check_for_downleft

	; down + right held, so sprite needs to be diagonal
	ld		a, 1				; diagonal sprite is tile 1
	ld		(spaceship_tile), a
	ld		a, SPRITE_FLAGS_YFLIP	; y flip the sprite
	ld		(spaceship_flags), a

	jp		adjust_down_pos

check_for_downleft
	; is left also held?
	ld		a, (joypad_held)
	bit		DPAD_LEFT, a
	jp		z, set_down_only

	; down + left held, so sprite needs to be diagonal
	ld		a, 1				; diagonal sprite is tile 1
	ld		(spaceship_tile), a
	ld		a, SPRITE_FLAGS_XFLIP + SPRITE_FLAGS_YFLIP	; sprite should be x and y flipped
	ld		(spaceship_flags), a

	jp		adjust_down_pos

set_down_only
	; only down was held, so sprite needs to be down
	ld		a, 0	; vertical sprite is tile 0
	ld		(spaceship_tile), a
	ld		a, SPRITE_FLAGS_YFLIP
	ld		(spaceship_flags), a

adjust_down_pos
	; adjust the sprite's position
	ld		a, (ScrollTimer)	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, check_for_left

	; move sprite up a pixel
	ld		a, (spaceship_ypos)
	inc		a
	ld		(spaceship_ypos), a

check_for_left
	ld		a, (joypad_held)
	bit		DPAD_LEFT, a
	jp		z, check_for_right	; if button not pressed then done

	; left was pressed
check_left_andUpOrDown
	ld		a, (joypad_held)
	and		DPAD_UP_MASK + DPAD_DOWN_MASK
	jp		nz, adjust_left_pos	; if up or down was pressed, then we already set the sprite attribs

	; sprite needs to be horizontal
	ld		a, 2		; horizontal sprite is tile 2
	ld		(spaceship_tile), a
	ld		a, SPRITE_FLAGS_XFLIP
	ld		(spaceship_flags), a

adjust_left_pos
	ld		a, (ScrollTimer)	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, done_checking_dpad

	; move sprite left one pixel
	ld		a, (spaceship_xpos)
	dec		a
	ld		(spaceship_xpos), a

	jp		done_checking_dpad	; if left was pressed, don't check right

check_for_right
	ld		a, (joypad_held)
	bit		DPAD_RIGHT, a
	jp		z, done_checking_dpad	; if button not pressed then done

	; right was pressed
check_right_andUpOrDown
	ld		a, (joypad_held)
	and		DPAD_UP_MASK + DPAD_DOWN_MASK
	jp		nz, adjust_right_pos	; if up or down was pressed, then we already set the sprite attribs

	; sprite needs to be horizontal
	ld		a, 2		; horizontal sprite is tile 2
	ld		(spaceship_tile), a
	ld		a, 0
	ld		(spaceship_flags), a

adjust_right_pos
	ld		a, (ScrollTimer)	; only move sprite every 2nd vblank
	and		%00000001
	jr		nz, done_checking_dpad

	; move sprite left one pixel
	ld		a, (spaceship_xpos)
	inc		a
	ld		(spaceship_xpos), a

	jp		done_checking_dpad	; if left was pressed, don't check right

done_checking_dpad
	ld		a, (joypad_down)
	bit		A_BUTTON, a
	jp		z, did_not_fire

	call	LaunchBullet

did_not_fire
	pop		af
	ret



;------------------------------------------------------------
; return the direction to fire a bullet in from the
; spaceship's sprite attribs
;
; OUT:		a = direction ship is facing (0..7)
;           b = x start location
;			c = y start location
;------------------------------------------------------------
GetBulletDirection
	ld		a, (spaceship_tile)		; what tile is the spaceship currently using?
	cp		1						; diagonal ship tile?
	jr		z, ship_is_diag

	; ship is either vertical or horizontal
	cp		0		; vertical ship tile?
	jr		nz, ship_is_horiz

	; vertical ship tile
	ld		a, (spaceship_flags)
	and     SPRITE_FLAGS_YFLIP	; is the ship pointing down?
	jp		nz,	ship_faces_down

ship_faces_up
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	add     a, 2
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	sub		3
	ld		c, a
	; direction is up
	ld		a, 0
	ret

ship_faces_down
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	add     a, 2
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	add		a, 8
	ld		c, a
	; direction is down
	ld		a, 4
	ret

ship_is_horiz
	; horizontal ship tile
	ld		a, (spaceship_flags)
	and     SPRITE_FLAGS_XFLIP	; is the ship pointing left?
	jp		nz,	ship_faces_left

ship_faces_right
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	add     a, 8
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	add		a, 2
	ld		c, a
	; direction is right
	ld		a, 2
	ret

ship_faces_left
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	sub     3
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	add		a, 2
	ld		c, a
	; direction is left
	ld		a, 6
	ret

ship_is_diag
	ld		a, (spaceship_flags)
	and		SPRITE_FLAGS_XFLIP	; x flipped?
	jp		nz, ship_is_x_flipped

ship_is_not_x_flipped
	ld		a, (spaceship_flags)
	and		SPRITE_FLAGS_YFLIP	; y flipped?
	jp		nz, ship_faces_downright

ship_faces_upright
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	add     a, 7
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	sub		2
	ld		c, a
	; direction is up-right
	ld		a, 1
	ret

ship_faces_downright
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	add     a, 7
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	add		a, 7
	ld		c, a
	; direction is down-right
	ld		a, 3
	ret

ship_is_x_flipped
	ld		a, (spaceship_flags)
	and		SPRITE_FLAGS_YFLIP	; y flipped?
	jp		nz, ship_faces_downleft

ship_faces_upleft
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	sub     2
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	sub		2
	ld		c, a
	; direction is up-left
	ld		a, 7
	ret

ship_faces_downleft
	; calc bullet x launch pos
	ld		a, (spaceship_xpos)
	sub     2
	ld		b, a
	; calc bullet y launch pos
	ld		a, (spaceship_ypos)
	add		a, 7
	ld		c, a
	; direction is down-left
	ld		a, 5
	ret


;------------------------------------------------------------
; launch a bullet
;------------------------------------------------------------
LaunchBullet
	push	af
	push	bc
	push	de

	; find an empty bullet
	ld		hl, bullet_data		; get the addr of the 1st bullet
	ld		d, 16				; 16 bullet slots to check
find_empty_bullet_loop
	ld		a, (hl)
	cp		$ff			; is this bullet unused
	jr		z, found_empty_bullet

	inc		hl	; skip 2 bytes, to top of next bullet
	inc		hl

	dec		d
	jr		nz, find_empty_bullet_loop

	; no slots left... exit
	pop		de
	pop		bc
	pop		af
	ret

found_empty_bullet
	call	GetBulletDirection	; get the direction and offset to fire the bullet at
	; a = orientation
	; b = x pos
	; c = y pos
	; hl = bullet data to launch
	; index into bullet array = 16 - d

	ld		(hli), a	; store the orientation
	ld		(hl), 60	; bullet lasts 1 second (60 vblanks)

	ld		a, 16
	sub		d		; a = index into bullet array

	ld		hl, bullet_sprites	; get top of bullet sprites

	sla		a
	sla		a		; multiply index by 4 (4 bytes per sprite)
	ld		e, a	; store it in de
	ld		d, 0

	add		hl, de	; I should be pointing at the correct sprite addr

	; load the sprite info
	ld		(hl), c
	inc		hl
	ld		(hl), b
	inc		hl
	ld		(hl), 5	; bullets use tile 5
	inc		hl
	ld		(hl), 0

	pop		de
	pop		bc
	pop		af
	ret


;-----------------------------------------------------------------
; update the bullet timing ever vblank
;-----------------------------------------------------------------
UpdateBulletTimers
	push	af
	push	bc
	push	hl

	ld		hl, bullet_data
	ld		b, 16		; 16 bullets to update
update_bullets_loop
	ld		a, (hli)
	cp		$ff
	jr		z, update_bullets_loop_end

	; this is an active bullet
	dec		(hl)	; decrement the timer
	jr		nz, update_bullets_loop_end

	; this bullet's timer ran out
	push	hl		; save where we were
	push	bc

	dec		hl		; go back a byte
	ld		a, $ff
	ld		(hl), a	; this sprite is no longer active

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
	ld		(hli), a
	ld		(hl), a		; turn of the sprite in the attrib table
	pop		bc
	pop		hl

update_bullets_loop_end
	inc		hl
	dec		b
	jr		nz, update_bullets_loop

	pop		hl
	pop		bc
	pop		af
	ret


;------------------------------------------------------
; update bullet positions
;------------------------------------------------------
UpdateBulletPositions
	push	af
;	ld		a, (ScrollTimer)	; only move bullets every 2nd vblank
;	and		%00000001
;	jr		z, update_bullets_pos
;
;	pop		af
;	ret
;
;update_bullets_pos
	push	bc

	ld		hl, bullet_data
	ld		b, 16		; 16 bullets to update
update_bullets_pos_loop
	ld		a, (hl)
	cp		$ff
	jp		z, update_bullets_pos_loop_end

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

check_bullet_fly_up
	ld		a, (hl)		; get the orientation info
	cp		0		; flying up?
	jr		nz, check_bullet_fly_upright

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	sub		3
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_upright
	ld		a, (hl)		; get the orientation info
	cp		1		; flying up-right?
	jr		nz, check_bullet_fly_right

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	sub		2
	ld		(hli), a
	ld		a, (hl)
	add		a, 2
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_right
	ld		a, (hl)		; get the orientation info
	cp		2		; flying right?
	jr		nz, check_bullet_fly_downright

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, (hl)
	add		a, 2
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_downright
	ld		a, (hl)		; get the orientation info
	cp		3		; flying down-right?
	jr		nz, check_bullet_fly_down

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	add		a, 2
	ld		(hli), a
	ld		a, (hl)
	add		a, 2
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_down
	ld		a, (hl)		; get the orientation info
	cp		4		; flying down?
	jr		nz, check_bullet_fly_downleft

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	add		a, 3
	ld		(hl), a
	pop		hl

	jr		update_bullets_pos_loop_end

check_bullet_fly_downleft
	ld		a, (hl)		; get the orientation info
	cp		5		; flying down-left?
	jr		nz, check_bullet_fly_left

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	add		a, 2
	ld		(hli), a
	ld		a, (hl)
	sub		2
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_left
	ld		a, (hl)		; get the orientation info
	cp		6		; flying left?
	jr		nz, check_bullet_fly_upleft

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	inc		hl
	ld		a, (hl)
	sub		3
	ld		(hl), a
	pop		hl

	jp		update_bullets_pos_loop_end

check_bullet_fly_upleft
	ld		a, (hl)		; get the orientation info
	cp		7		; flying up-left?
	jr		nz, update_bullets_pos_loop_end

	; update this sprite's position
	push	hl
	ld		h, d
	ld		l, e	; grab the sprite address
	ld		a, (hl)
	sub		2
	ld		(hli), a
	ld		a, (hl)
	sub		2
	ld		(hl), a
	pop		hl

update_bullets_pos_loop_end
	inc		hl
	inc		hl
	dec		b
	jp		nz, update_bullets_pos_loop

	pop		bc
	pop		af
	ret





; tiles are here
TileData
#include "tgTiles.dat"

; map is here
BkgMapData
; 32x32 tiles
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03
.db		$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03,$04,$03




;-------------------------------------------------------------------------
; Internal RAM... store dynamic data here
;-------------------------------------------------------------------------
.org $c000
; local version of sprite attrib table
spaceship_ypos
.db		$00
spaceship_xpos
.db		$00
spaceship_tile
.db		$00
spaceship_flags
.db		$00

; bullet sprites start here (16 of them)
bullet_sprites
.db		$00





.org $c0a0
; other variables

; frame timing
vblank_flag
.db		$00		; set if a vblank occured since last pass through game loop

; joypad values
joypad_held
.db		$00		; what buttons are currently held
joypad_down
.db		$00		; what buttons went down since last joypad read

; bullets (16 of them, 2 bytes for each)
;	1st byte = orientation (3 bits) - if $ff, this bullet is unused
;	2nd byte = time left to live (in vblanks)
bullet_data
.db		$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.db		$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


; temp variables
ScrollTimer
.db		$00		; temp variable for slowing down scroll speed






.block $008000-$
.end start

