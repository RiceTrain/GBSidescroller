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

AUD_1_SWEEP				equ		$10
AUD_1_LENGTH			equ		$11
AUD_1_ENV				equ		$12
AUD_1_LOW				equ		$13
AUD_1_HIGH				equ		$14
AUD_2_LENGTH			equ		$16
AUD_2_ENV				equ		$17
AUD_2_LOW				equ		$18
AUD_2_HIGH				equ		$19
AUD_3_ENA				equ		$1A
AUD_3_LENGTH			equ		$1B
AUD_3_LEVEL				equ		$1C
AUD_3_LOW				equ		$1D
AUD_3_HIGH				equ		$1E
AUD_4_LENGTH			equ		$20
AUD_4_ENV				equ		$21
AUD_4_POLY				equ		$22
AUD_4_GO				equ		$23
AUD_VOLUME				equ		$24
AUD_TERM				equ		$25
AUD_ENA					equ		$26

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
RST_00:	
	jp	$100

SECTION	"Org $08",HOME[$08]
RST_08:	
	jp	$100

SECTION	"Org $10",HOME[$10]
RST_10:
	jp	$100

SECTION	"Org $18",HOME[$18]
RST_18:
	jp	$100

SECTION	"Org $20",HOME[$20]
RST_20:
	jp	$100

SECTION	"Org $28",HOME[$28]
RST_28:
    ; pop return address off stack into hl
    pop hl
    push bc
    
    ; here we get the number of bytes to copy
    ; hl contains the address of the bytes following the "rst $28" call
    
    ; put first byte into b ($00 in this context)
    ld  a,[hli]
    ld  b,a
    
    ; put second byte into c ($0D in this context)
    ld  a,[hli]
    ld  c,a
    
    ; bc now contains $000D
    ; hl now points to the first byte of our assembled subroutine (which is $F5)
    ; begin copying data
.copy_data_loop
  
	; load a byte of data into a
	ld  a,[hli]

	; store the byte in de, our destination ($FF80 in this context)
	ld  [de],a
	
	; go to the next destination byte, decrease counter
	inc de
	dec bc

	; check if counter is zero, if not repeat loop
	ld  a,b
	or  c
	jr  nz,.copy_data_loop
	
	; all done, return home
	pop bc
	push hl
	reti

;SECTION	"Org $38",HOME[$38]
;RST_38:
;	jp	$100
	
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
	jp 		start         ; goto beginning of game code

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