; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address

; Lowest enemy behaviour id: 18

;------------------------------------------------------
; setup enemies
; hl = data address of enemy (tile no already set)
;------------------------------------------------------
SetupNewEnemy::
	ld		a, [hli]
	
	cp		18
	jr		z, .enemy_0_data
	cp		19
	jr		z, .enemy_1_data
	
.enemy_0_data
	call	Enemy0Data
	jp		.anim_data_setup
.enemy_1_data
	call	Enemy1Data
	jp		.anim_data_setup
	
.anim_data_setup
	call	GetAnimationData
	ld		a, [hl]
	cp		$ff
	jr		z, .cancel_setup
	
	ld		a, [enemy_tile]
	cp		18
	jr		z, .enemy_0_anim_sprite
	cp		19
	jr		z, .enemy_1_anim_sprite
	
.enemy_0_anim_sprite
	call	Enemy0AnimSprite
	jp		.end_setup
.enemy_1_anim_sprite
	call	Enemy1AnimSprite
	jp		.end_setup
	
.cancel_setup
	dec		hl
	dec		hl
	dec		hl
	dec		hl
	ld		a, $ff
	ld		[hl], a
	
.end_setup
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
	
.setup1x1AnimData
	ld		de, enemy_animation_data_1x1
	ld		b, 8
	ld		c, 4
	jp		.get_anim_data_loop
	
.setup2x1AnimData
	ld		de, enemy_animation_data_2x1
	ld		b, 5
	ld		c, 6
	jp		.get_anim_data_loop
	
.setup2x2AnimData
	ld		de, enemy_animation_data_2x2
	ld		b, 3
	ld		c, 10
	
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
	
.setup1x1SpriteData
	ld		de, enemy_sprites_1x1
	ld		b, 8
	ld		c, 1
	jp		.get_sprite_loop
	
.setup2x1SpriteData
	ld		de, enemy_sprites_2x1
	ld		b, 5
	ld		c, 2
	jp		.get_sprite_loop
	
.setup2x2SpriteData
	ld		de, enemy_sprites_2x2
	ld		b, 3
	ld		c, 4
	
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
	
	ld		a, e
	ld		[bc], a

	ret
	
INCLUDE "Projects/PieInTheSky/EnemySetup.asm"