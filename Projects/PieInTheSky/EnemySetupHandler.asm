; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address
; byte 6: misc
; byte 7: misc
; byte 8: misc

INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyEnemyData.z80"
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyEnemyAnimData1x1.z80"
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyEnemyAnimData2x1.z80"
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyEnemyAnimData2x2.z80"
INCLUDE "Projects/PieInTheSky/Data/PieInTheSkyEnemyAnimDataBoss.z80"

;------------------------------------------------------
; setup enemies
; hl = data address of enemy (tile no already set)
;------------------------------------------------------
SetupNewEnemy::
	inc 	hl
	
	ld		a, [current_level_enemy_data_upper]
	ld		d, a
	ld		a, [current_level_enemy_data_lower]
	ld		e, a
	
	ld		a, [current_level_enemy_count]
	ld		c, a
	
	ld		a, [current_level_enemy_length]
	ld		b, a
.find_enemy_in_data_loop
	ld		a, 0
	cp		c
	jr		z, .enemy_data_found
	push	hl
	ld		h, d
	ld		l, e
	ld		d, 0
	ld		a, EnemyBehaviourDataItemLength
	ld		e, a
	add		hl, de
	ld		d, h
	ld		e, l
	pop		hl
	
	dec 	c
	dec 	b
	jp		z, .cancel_setup_data
	jr		nz, .find_enemy_in_data_loop
	
.enemy_data_found
	ld		a, [enemy_data_size]
	dec		a
	dec 	a
	ld		b, a
.enemy_data_found_loop
	inc		de
	ld		a, b
	cp		4
	jr		nz, .continue_with_loop
	inc 	hl ;skips where the animation address will be stored
	
.continue_with_loop
	ld		a, [de]
	ld		[hli], a
	dec		b
	jr		nz, .enemy_data_found_loop
	
	call 	StoreEnemySpawnPositions
	
	dec		hl
	ld		a, 0
	ld		[hl], a
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	
.anim_data_setup
	call	GetAnimationData
	ld		a, [hl]
	cp		$ff
	jp		z, .cancel_setup_anim
	
	push	hl
	
	ld		a, c
	ld		[new_enemy_anim_data_length], a
	cp		4
	jr		z, .enemy_1x1_anim_sprite
	cp		6
	jr		z, .enemy_2x1_anim_sprite
	cp		10
	jr		z, .enemy_2x2_anim_sprite
	cp		0
	jr		z, .boss_anim_sprite
	
.enemy_1x1_anim_sprite
	ld		hl, EnemyAnim1x1Data
	ld		a, EnemyAnimData1x1Count
	ld		b, a
	ld		c, 5
	jr		.find_anim_data
.enemy_2x1_anim_sprite
	ld		hl, EnemyAnim2x1Data
	ld		a, EnemyAnimData2x1Count
	ld		b, a
	ld		c, 8
	jr		.find_anim_data
.enemy_2x2_anim_sprite
	ld		hl, EnemyAnim2x2Data
	ld		a, EnemyAnimData2x2Count
	ld		b, a
	ld		c, 14
	jr		.find_anim_data
.boss_anim_sprite
	ld		hl, EnemyAnimBossData
	ld		a, EnemyAnimDataBossCount
	ld		b, a
	ld		c, 29
	
.find_anim_data
	push	de
	ld		a, [enemy_tile]
	ld		d, a
.find_anim_data_loop
	ld		a, [hl]
	cp		d
	jr		z, .enemy_anim_data_found
	
	dec		b
	ld		d, 0
	ld		e, c
	add		hl, de
	ld		a, [enemy_tile]
	ld		d, a
	
	jr		nz, .find_anim_data_loop
	
.enemy_anim_data_found
	ld		a, [new_enemy_anim_data_length]
	cp		4
	jr		z, .enemy_1x1_anim_data_length
	cp		6
	jr		z, .enemy_2x1_anim_data_length
	cp		10
	jr		z, .enemy_2x2_anim_data_length
	cp		0
	jr		z, .boss_anim_data_length
	
.enemy_1x1_anim_data_length
	ld		b, 3
	jr		.transfer_anim_data
.enemy_2x1_anim_data_length
	ld		b, 5
	jr		.transfer_anim_data
.enemy_2x2_anim_data_length
	ld		b, 9
	jr		.transfer_anim_data
.boss_anim_data_length
	ld		b, 19

.transfer_anim_data
	pop 	de
	inc		de
	inc		hl
.transfer_anim_data_loop
	ld		a, [hli]
	ld		[de], a
	inc 	de
	dec		b
	jr		nz, .transfer_anim_data_loop
	
.set_initial_sprites
	dec 	de
	ld		b, h
	ld		c, l
	pop		hl
	
	push	bc
	call	GetEmptySpriteAddress
	pop 	bc
	
	ld		h, b
	ld		l, c
	
.find_data_length_needed
	ld		a, [new_enemy_anim_data_length]
	cp		4
	jr		z, .enemy_1x1_anim_data_length_remaining
	cp		6
	jr		z, .enemy_2x1_anim_data_length_remaining
	cp		10
	jr		z, .enemy_2x2_anim_data_length_remaining
	cp		0
	jr		z, .boss_anim_data_length_remaining
	
.enemy_1x1_anim_data_length_remaining
	call	Enemy1x1SpriteSetup
	jr		.sprite_data_set
.enemy_2x1_anim_data_length_remaining
	ld		a, [enemy_tile_width]
	cp		1
	jr		z, .use_1x2
	
	call	Enemy2x1SpriteSetup
	jr		.sprite_data_set
	
.use_1x2
	call	Enemy1x2SpriteSetup
	jr		.sprite_data_set
.enemy_2x2_anim_data_length_remaining
	call	Enemy2x2SpriteSetup
	jr		.sprite_data_set
.boss_anim_data_length_remaining
	call 	BossSpriteSetup

.sprite_data_set
	jr		.end_setup
	
.cancel_setup_anim
	dec		hl
	dec		hl
	dec		hl
.cancel_setup_data
	dec		hl
	ld		a, $ff
	ld		[hl], a
	
.end_setup
	ld		a, [current_level_enemy_count]
	inc 	a
	ld		[current_level_enemy_count], a
	ret

;----------------------------------------------
; Gets enemy start position and stores in
; new_enemy_x_pos && new_enemy_y_pos
;----------------------------------------------
StoreEnemySpawnPositions::
	ld		a, [de]
	and 	%00000011
	cp		0
	jr		nz, .check_if_left
	
	ld		b, 8
	ld		c, 8
	call 	AddToXSpawnPosition
	jr		.position_set
.check_if_left
	cp		3
	jr		nz, .check_if_right

	ld		b, 8
	ld		c, 8
	call 	AddToYSpawnPosition
	jr		.position_set
.check_if_right
	cp 		1
	jr		nz, .set_bottom_position
	
	ld		b, 160
	ld		c, 8
	call 	AddToYSpawnPosition
	jr		.position_set
.set_bottom_position
	ld		b, 8
	ld		c, 144
	call 	AddToXSpawnPosition
.position_set
	ld		a, b
	ld		[new_enemy_x_pos], a
	ld		a, c
	ld		[new_enemy_y_pos], a
	ret
	
AddToXSpawnPosition::
	push 	hl
	
	ld		a, [de]
	and 	%11111100
	srl 	a
	srl 	a
	ld		h, a
	inc 	h
	
	ld		a, b
.add_loop
	dec 	h
	jr		z, .finish_add_loop
	
	add 	a, 5
	jr 		.add_loop
	
.finish_add_loop
	ld		b, a
	pop 	hl
	ret
	
AddToYSpawnPosition::
	push 	hl
	
	ld		a, [de]
	and 	%11111100
	srl 	a
	srl 	a
	ld		h, a
	inc 	h
	
	ld		a, c
.add_loop
	dec 	h
	jr		z, .finish_add_loop
	
	add 	a, 4
	jr 		.add_loop
	
.finish_add_loop
	ld		c, a
	pop 	hl
	ret
	
; enemy animation data setup
; byte 1: sprite lower address
; byte 2: anim time
; byte 3-4/6/10: tile number
;----------------------------------------------
; Gets an empty anim data and stores in de
;----------------------------------------------
GetAnimationData::
	dec		hl
	dec		hl
	ld		a, [hl]
	ld		c, a
	ld		[enemy_tile_width], a
	inc		hl
	ld		a, [hl]
	add		a, c
	ld		[enemy_tile_count], a
	inc		hl
	
	cp		2
	jr		z, .setup1x1AnimData
	cp		3
	jr		z, .setup2x1AnimData
	cp		4
	jr		z, .setup2x2AnimData
	cp		6
	jr		z, .setupBossAnimData
	
.setup1x1AnimData
	ld		de, enemy_animation_data_1x1
	ld		b, 8
	ld		c, 4
	jr		.get_anim_data_loop
	
.setup2x1AnimData
	ld		de, enemy_animation_data_2x1
	ld		b, 5
	ld		c, 6
	jr		.get_anim_data_loop
	
.setup2x2AnimData
	ld		de, enemy_animation_data_2x2
	ld		b, 3
	ld		c, 10
	jr		.get_anim_data_loop
	
.setupBossAnimData
	ld		de, boss_animation_data
	ld		c, 0
	jr		.found_empty_anim_data
	
.get_anim_data_loop
	ld		a, [de]
	cp		$ff
	jr		z, .found_empty_anim_data
	
	ld		a, c
.move_to_next_anim_data_loop
	inc		de
	dec		a
	jr		nz, .move_to_next_anim_data_loop
	
	dec		b
	jr		nz, .get_anim_data_loop
	
	ld		a, $ff
	ld		[hl], a
	
	ret
	
.found_empty_anim_data
	ld		a, e
	ld		[hl], a
	
	ret
	
;-----------------------------------------------
; Gets an empty sprite address and stores in de
;-----------------------------------------------
GetEmptySpriteAddress::
	ld		a, [enemy_tile_count]
	
	cp		2
	jr		z, .setup1x1SpriteData
	cp		3
	jr		z, .setup2x1SpriteData
	cp		4
	jr		z, .setup2x2SpriteData
	cp		6
	jr		z, .setupBossSpriteData
	
.setup1x1SpriteData
	ld		de, enemy_sprites_1x1
	ld		b, 8
	ld		c, 1
	jr		.get_sprite_loop
	
.setup2x1SpriteData
	ld		de, enemy_sprites_2x1
	ld		b, 5
	ld		c, 2
	jr		.get_sprite_loop
	
.setup2x2SpriteData
	ld		de, enemy_sprites_2x2
	ld		b, 3
	ld		c, 4
	jr		.get_sprite_loop
	
.setupBossSpriteData
	ld		de, enemy_sprites_2x2
	ld		b, $c1
	ld		a, [hl]
	ld		c, a
	
	jr		.store_sprite_address
	
.get_sprite_loop
	ld		a, [de]
	cp		0
	jr		nz, .sprite_being_used
	inc		de
	ld		a, [de]
	dec		de
	cp		0
	jr		z, .found_empty_sprite

.sprite_being_used
	ld		a, c
.move_to_next_sprite_set_loop
	inc		de
	inc		de
	inc		de
	inc		de
	dec		a
	jr		nz, .move_to_next_sprite_set_loop
	
	dec		b
	jr		nz, .get_sprite_loop
	
	ret
	
.found_empty_sprite
	ld		b, $c0
	ld		a, [hl]
	ld		c, a
	
.store_sprite_address
	ld		a, e
	ld		[bc], a

	ret
	
INCLUDE "Projects/PieInTheSky/EnemySetup.asm"