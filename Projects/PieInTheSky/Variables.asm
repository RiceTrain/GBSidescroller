InitWorkingVariables::
	ld		a, 0
	ld		[vblank_flag], a
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	
	ld		a, $ff
	ld		[checkpoint_pixels], a
	
	ret

;------------------------------------------
; init the local copy of the sprites
;------------------------------------------
InitSprites::
	ld		hl, $c000	; my sprites are at $c000
	ld		b, 40*4		; 40 sprites, 4 bytes per sprite
	ld		a, 0
.init_sprites_loop
	ld		[hli], a
	dec		b
	jr		nz, .init_sprites_loop
	
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

spaceshipLAnim1_ypos:
ds		1
spaceshipLAnim1_xpos:
ds		1
spaceshipLAnim1_tile:
ds		1
spaceshipLAnim1_flags:
ds		1

spaceshipLAnim2_ypos:
ds		1
spaceshipLAnim2_xpos:
ds		1
spaceshipLAnim2_tile:
ds		1
spaceshipLAnim2_flags:
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

;1x1 enemy sprites start here (8 * 1 of them)
enemy_sprites_1x1:
ds		32
;2x1 enemy sprites start here (5 * 2 of them)
enemy_sprites_2x1:
ds		40
;2x2 enemy sprites start here (3 * 4 of them)
enemy_sprites_2x2:
ds		48

SECTION	"RAM_Working_Variables",BSS[$c0A0]

; Enemy anim data starts here (8 * 4 of them)
enemy_animation_data_1x1:
ds		32
; Enemy anim data starts here (5 * 6 of them)
enemy_animation_data_2x1:
ds		30
; Enemy anim data starts here (3 * 10 of them)
enemy_animation_data_2x2:
ds		30
; Enemy data starts here (16 * 5 of them)
enemy_data:
ds		128

boss_animation_data:
ds		20

enemy_data_size:
ds		1

enemy_tile:
ds		1;
new_enemy_y_pos:
ds		1;
enemy_tile_count:
ds		1;

bullet_data:
ds		8

current_bullet_direction:
ds		1
current_bullet_xpos:
ds		1
current_bullet_ypos:
ds		1
current_enemy_index:
ds		1
current_enemy_address_upper:
ds		1
current_enemy_address_lower:
ds		1

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
player_animation_timer:
ds		1
current_anim_frame_upper:
ds		1
current_anim_frame_lower:
ds		1

;checkpoint data
checkpoint_pixels:
ds		1
checkpoint_appearance_map_block:
ds		1
checkpoint_appearance_tiles_scrolled:
ds		1
checkpoint_appearance_ship_y:
ds		1
checkpoint_map_block:
ds		1
checkpoint_tiles_scrolled:
ds		1
checkpoint_ship_y:
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
CurrentBGMapScrollTileX:
ds		1;
CurrentWindowTileX:
ds		1;
CurrentMapBlock:
ds		1;
TestMapBlockTotal:
ds		1;

CurrentColumnHeight:
ds		1;

;level state
level_end_reached:
ds		1
boss_defeated:
ds		1