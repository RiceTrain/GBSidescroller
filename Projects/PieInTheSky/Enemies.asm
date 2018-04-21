InitEnemyData::
	ld		d, 0
	
	; init my enemy sprites
	ld		hl, enemy_data
	ld		b, 16		; 16 enemies in table
.init_enemy_data_loop
	ld 		a, $ff
	ld		[hl], a
	ld		e, 5		; 5 bytes per enemy
	add		hl, de

	dec		b
	jr		nz, .init_enemy_data_loop
	
	ld		hl, enemy_animation_data_1x1
	ld		b, 8		; 8 enemies in 1x1 table
.init_1x1_enemy_anim_data_loop
	ld 		a, $ff
	ld		[hl], a
	ld		e, 4
	add		hl, de
	
	dec		b
	jr		nz, .init_1x1_enemy_anim_data_loop
	
	ld		hl, enemy_animation_data_2x1
	ld		b, 5		; 5 enemies in 2x1 table
.init_2x1_enemy_anim_data_loop
	ld 		a, $ff
	ld		[hl], a
	ld		e, 6
	add		hl, de
	
	dec		b
	jr		nz, .init_2x1_enemy_anim_data_loop
	
	ld		hl, enemy_animation_data_2x2
	ld		b, 3		; 3 enemies in 2x2 table
.init_2x2_enemy_anim_data_loop
	ld 		a, $ff
	ld		[hl], a
	ld		e, 10
	add		hl, de
	
	dec		b
	jr		nz, .init_2x2_enemy_anim_data_loop
	
.init_boss_anim_data
	ld		hl, boss_animation_data
	ld 		a, $ff
	ld		[hl], a
	
	ret
	
;------------------------------------------------------
; update enemy scroll position
;------------------------------------------------------
UpdateEnemyScrollPositions::
	ld		hl, enemy_data
	ld		b, 16		; 16 enemies to update
.update_enemies_pos_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_enemies_pos_loop_end
	inc		hl
	ld		a, [hl]
	dec		hl
	cp		0
	jp		z, .update_enemies_pos_loop_end

	push	de
	push	bc
	
	call	GetSpriteAddress

.enemy_scroll_left
	; update this sprite's position
	inc		de
	ld		a, [de]
	dec		a
	ld		[de], a
	dec		de
	
	call	UpdateEnemySpritePositions
	
	pop		bc
	pop		de

.update_enemies_pos_loop_end
	inc		hl
	inc		hl
	inc		hl
	inc 	hl
	inc 	hl
	dec		b
	jp		nz, .update_enemies_pos_loop
	
	ret
	
;-------------------------------------------------------------
; Creates an enemy sprite
;-------------------------------------------------------------	
CreateEnemy::
	;store tile id
	ld		a, [hl]
	ld		[enemy_tile], a
	
	push	af
	push	de
	push	hl
	push	bc
	
	; find an empty enemy
	ld		hl, enemy_data		; get the addr of the 1st enemy
	ld		b, 16				; 16 enemy slots to check
.find_empty_enemy_loop
	ld		a, [hl]
	cp		$ff			; is this enemy unused
	jr		z, .found_empty_enemy

	inc		hl	; skip 5 bytes, to top of next enemy
	inc		hl
	inc		hl
	inc		hl
	inc		hl

	dec		b
	jr		nz, .find_empty_enemy_loop

	; no slots left... exit
	pop		bc
	pop 	hl
	pop		de
	pop		af
	ret

.found_empty_enemy
	; calc enemy y pos
	ld		a, [CurrentColumnHeight]
	ld		e, a
	ld		a, 34
	sub		e
	ld		e, a
	ld		a, 0
	
.calculate_y_loop
	add		a, 8
	dec		e
	jr		nz, .calculate_y_loop
	
	ld		[new_enemy_y_pos], a 
	
	; [new_enemy_y_pos] = y pos
	; [enemy_tile] = tile number
	; hl = enemy data top

	ld		a, [enemy_tile]
	ld		[hl], a	; store the tile no
	call	SetupNewEnemy

	pop		bc
	pop 	hl
	pop		de
	pop		af
	
	ret

INCLUDE "Projects/PieInTheSky/EnemySetupHandler.asm"

;------------------------------------------------------
; update enemy behaviours
;------------------------------------------------------
UpdateEnemyBehaviours::
	ld		hl, enemy_data
	ld		b, 16		; 16 enemies to update
.update_enemies_loop
	ld		a, [hl]
	cp		$ff
	jp		z, .update_enemies_loop_end

	push	bc
	call 	UpdateEnemyBehaviour
	call	UpdateEnemyAnimation
	pop		bc

.update_enemies_loop_end
	inc		hl
	inc		hl
	inc		hl
	inc		hl
	inc		hl ;5 bytes per enemy data
	dec		b
	jp		nz, .update_enemies_loop
	
	ret

;------------------------------------------------------
; Check if enemy tile - z flag set if true
;------------------------------------------------------
CheckIfEnemyTile::
	cp		18
	jp		z, .done_checking
	cp		19
	jp		z, .done_checking
	cp		23
	jp		z, .done_checking
	
.done_checking
	ret

;------------------------------------------------------
; enemy just defeated, start death anim
;------------------------------------------------------
StartEnemyExplosion::
	push	bc
	
	inc		hl
	inc		hl
	ld		a, [hl]
	ld		b, a
	inc		hl
	ld		a, [hl]
	add		a, b
	dec		hl
	dec		hl
	dec		hl
	
	cp		2
	jr		z, .sprite_1x1_count
	cp		3
	jr		z, .sprite_2x1_count
	cp		4
	jr		z, .sprite_2x2_count
	cp		6
	jr		z, .sprite_boss_count
	
.sprite_1x1_count
	ld		a, 20
	ld		[hl], a
	
	inc		de
	inc		de
	ld		a, 20
	ld		[de], a
	jp		.end_routine
	
.sprite_2x1_count
	ld		a, 30
	ld		[hl], a
	
	ld		a, b
	cp		1
	jr		z, .move_sprite_down
.move_sprite_right
	inc		de
	ld		a, [de]
	add		a, 4
	ld		[de], a
	dec		de
	jr		.finished_moving_sprite
.move_sprite_down
	ld		a, [de]
	add		a, 4
	ld		[de], a
.finished_moving_sprite
	ld		b, 1
	jr		.display_explosion_tile
	
.sprite_2x2_count
	ld		a, 40
	ld		[hl], a
	
	ld		a, [de]
	add		a, 4
	ld		[de], a
	inc		de
	ld		a, [de]
	add		a, 4
	ld		[de], a
	dec		de
	ld		b, 3
	jr		.display_explosion_tile
	
.sprite_boss_count
	ld		a, 40
	ld		[hl], a
	
	ld		a, [de]
	add		a, 8
	ld		[de], a
	inc		de
	ld		a, [de]
	add		a, 8
	ld		[de], a
	dec		de
	ld		b, 8
	
.display_explosion_tile
	inc		de
	inc		de
	ld		a, 20
	ld		[de], a
	inc		de
	inc		de

.hide_sprites_loop
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	inc		de
	inc		de
	
	dec		b
	jr		nz, .hide_sprites_loop
	
.end_routine
	pop		bc
	ret
	
;------------------------------------------------------
; clean up an enemy - hl = enemy_data, de = sprite
;------------------------------------------------------
CleanupEnemy::
	push	bc
	
	ld		a, $ff
	ld		[hl], a
	
	inc		hl
	inc		hl
	ld		a, [hl]
	inc		hl
	inc		hl
	
	ld		b, $c0
	cp		3
	jr		nz, .get_anim_data_address
	
	inc		b
	
	ld		a, 1
	ld		[boss_defeated], a
	
.get_anim_data_address
	ld		a, [hl]
	ld		c, a
	
	ld		a, $ff
	ld		[bc], a
	
	dec		hl
	dec		hl
	ld		a, [hl]
	ld		b, a
	inc		hl
	ld		a, [hl]
	add		a, b
	dec		hl
	dec		hl
	dec		hl
	
	cp		2
	jr		z, .sprite_1x1_count
	cp		3
	jr		z, .sprite_2x1_count
	cp		4
	jr		z, .sprite_2x2_count
	cp		6
	jr		z, .sprite_boss_count
	
.sprite_1x1_count
	ld		b, 1
	jr		.hide_sprites_loop
.sprite_2x1_count
	ld		b, 2
	jr		.hide_sprites_loop
.sprite_2x2_count
	ld		b, 4
	jr		.hide_sprites_loop
.sprite_boss_count
	ld		b, 9

.hide_sprites_loop
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	inc		de
	inc		de
	
	dec		b
	jr		nz, .hide_sprites_loop
	
	pop		bc
	ret
	
INCLUDE "Projects/PieInTheSky/EnemyBehaviourHandler.asm"
INCLUDE "Projects/PieInTheSky/EnemyAnimations.asm"