InitWorkingVariables::
	ld		a, 0
	ld		[vblank_flag], a
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	
	ret

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

	call 	InitBulletSprites
	call 	InitEnemySprites
	
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

spaceshipGun_ypos:
ds		1
spaceshipGun_xpos:
ds		1
spaceshipGun_tile:
ds		1
spaceshipGun_flags:
ds		1

spaceshipGunVertical_ypos:
ds		1
spaceshipGunVertical_xpos:
ds		1
spaceshipGunVertical_tile:
ds		1
spaceshipGunVertical_flags:
ds		1

; bullet sprites start here (4 of them)
bullet_sprites:
ds		16

; enemy sprites start here (6 of them)
enemy_sprites:
ds		24

SECTION	"RAM_Working_Variables",BSS[$c0A0]

; frame timing
vblank_flag:
ds		1		; set if a vblank occured since last pass through game loop

; joypad values
joypad_held:
ds		1		; what buttons are currently held
joypad_down:
ds		1		; what buttons went down since last joypad read

; player data
alive:	
ds		1
death_timer:	
ds		1
checkpoint_map_block:
ds		1
checkpoint_tiles_scrolled:
ds		1
checkpoint_ship_y:
ds		1
checkpoint_ship_x:
ds		1

bullet_data:
ds		8

enemy_data:
ds		24

current_bullet_direction:
ds		1
current_bullet_xpos:
ds		1
current_bullet_ypos:
ds		1

current_enemy_width:
ds		1
current_enemy_height:
ds		1

; temp variables
ScrollTimer:
ds		1		; temp variable for slowing down scroll speed

PixelsScrolled:
ds		1;
TotalTilesScrolled:
ds		1;
PrevMapColumnPos:
ds		1;
CurrentMapColumnPos:
ds		1;
CurrentBGMapScrollTileX:
ds		1;
CurrentWindowTileX:
ds		1;
CurrentMapBlock:
ds		1;

CurrentColumnHeight:
ds		1;
NewEnemyTile:
ds		1;