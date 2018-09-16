;-------------------------------------------------------------------------
; Internal RAM... store dynamic data here
;-------------------------------------------------------------------------
SECTION	"RAM_Start_Sprites",WRAM0[$c000]
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

SECTION	"RAM_Working_Variables",WRAM0[$c0A0]

; Enemy anim data starts here (8 * 4 of them)
enemy_animation_data_1x1:
ds		32
; Enemy anim data starts here (5 * 6 of them)
enemy_animation_data_2x1:
ds		30
; Enemy anim data starts here (3 * 10 of them)
enemy_animation_data_2x2:
ds		30
; Enemy data starts here (16 * 9 of them)
enemy_data:
ds		144

boss_animation_data:
ds		20

enemy_data_size:
ds		1

enemy_tile:
ds		1;
new_enemy_y_pos:
ds		1;
new_enemy_anim_data_length:
ds		1;
enemy_tile_count:
ds		1;
enemy_tile_width:
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
current_enemy_score_value:
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
lives:
ds		1

current_score:
ds		1
score_tracker_lower:
ds		1
score_tracker_higher:
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
checkpoint_current_score:
ds		1
checkpoint_score_tracker_lower:
ds		1
checkpoint_score_tracker_higher:
ds		1
enemies_destroyed:
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
CurrentTilesetWidth:
ds		1;

CurrentColumnHeight:
ds		1;

;level state
level_no:
ds		1
level_end_reached:
ds		1
boss_defeated:
ds		1
end_level_sequence_timer:
ds		1
end_level_sequence_phase:
ds		1
current_level_completion_bonus:
ds		1

;gbt_player vars
gbt_playing: DS 1

; pointer to the pattern pointer array
gbt_pattern_array_ptr:  DS 2 ; LSB first
IF DEF(GBT_USE_MBC5_512BANKS)
gbt_pattern_array_bank: DS 2 ; LSB first
ELSE
gbt_pattern_array_bank: DS 1
ENDC

; playing speed
gbt_speed:: DS 1

; Up to 12 bytes per step are copied here to be handled in functions in bank 1
gbt_temp_play_data:: DS 12

gbt_loop_enabled:            DS 1
gbt_ticks_elapsed::          DS 1
gbt_current_step::           DS 1
gbt_current_pattern::        DS 1
gbt_current_step_data_ptr::  DS 2 ; pointer to next step data - LSB first
IF DEF(GBT_USE_MBC5_512BANKS)
gbt_current_step_data_bank:: DS 2 ; bank of current pattern data - LSB first
ELSE
gbt_current_step_data_bank:: DS 1 ; bank of current pattern data
ENDC

gbt_channels_enabled:: DS 1

gbt_pan::   DS 4*1 ; Ch 1-4
gbt_vol::   DS 4*1 ; Ch 1-4
gbt_instr:: DS 4*1 ; Ch 1-4
gbt_freq::  DS 3*2 ; Ch 1-3

gbt_channel3_loaded_instrument:: DS 1 ; current loaded instrument ($FF if none)

; Arpeggio -> Ch 1-3
gbt_arpeggio_freq_index:: DS 3*3 ; {base index, base index+x, base index+y} * 3
gbt_arpeggio_enabled::    DS 3*1 ; if 0, disabled
gbt_arpeggio_tick::       DS 3*1

; Cut note
gbt_cut_note_tick:: DS 4*1 ; If tick == gbt_cut_note_tick, stop note.

; Last step of last pattern this is set to 1
gbt_have_to_stop_next_step:: DS 1

gbt_update_pattern_pointers:: DS 1 ; set to 1 by jump effects