;------------------------------------------------------
; update enemy behaviour
; hl = data address of enemy
; put hl back as it was once finished with it
;------------------------------------------------------
UpdateEnemyBehaviour::
	call	GetSpriteAddress
	
	inc		hl
	ld		a, [hl]
	dec		hl
	cp		0
	jr		nz, .enemy_alive_update
	
	call	UpdateDeadEnemy
	jp		.end_update
	
.enemy_alive_update
	ld		a, [hl]
	
	cp		18
	jr		z, .pattern_enemy_update
	
	cp		19
	jr		z, .enemy_1_update

	jp		.end_update
	
.pattern_enemy_update
	call	PatternEnemyUpdate
	jp		.update_sprite_positions
.enemy_1_update
	call	Enemy1Update
	jp		.update_sprite_positions
	
.update_sprite_positions
	call	UpdateEnemySpritePositions

.end_update
	ret
	
UpdateEnemySpritePositions::
	inc		hl
	ld		a, [hl]
	dec		hl
	cp		0
	jr		z, .end_update
	
	inc		hl
	inc		hl
	
	ld		a, [hl]
	ld		c, a
	inc		hl
	ld		a, [hl]
	add		a, c
	
	dec		hl
	dec		hl
	dec		hl
	
	cp		2
	jr		z, .end_update
	cp		3
	jr		z, .update_2x1
	cp		4
	jr		z, .update_2x2
	cp		6
	jr		z, .update_boss
	
.update_2x1
	ld		a, c
	cp		2
	jr		z, UpdateSpriteRight
	jr		nz, UpdateSpriteBelow

.update_2x2
	call	Update2x2
	jr		.end_update
	
.update_boss
	call	UpdateBossSpritePos
	
.end_update
	ret

UpdateSpriteRight::
	ld		a, [de]
	ld		b, a
	inc		de
	ld		a, [de]
	add		a, 8
	ld		c, a
	inc		de
	inc		de
	inc		de
	
	ld		a, b
	ld		[de], a
	inc		de
	ld		a, c
	ld		[de], a
	
	ret

UpdateSpriteBelow::
	ld		a, [de]
	add		a, 8
	ld		b, a
	inc		de
	ld		a, [de]
	ld		c, a
	inc		de
	inc		de
	inc		de
	
	ld		a, b
	ld		[de], a
	inc		de
	ld		a, c
	ld		[de], a
	ret

Update2x2::
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteBelow
	dec		de
	
	ld		a, [de]
	ld		b, a
	inc		de
	ld		a, [de]
	sub		8
	ld		c, a
	inc		de
	inc		de
	inc		de
	
	ld		a, b
	ld		[de], a
	inc		de
	ld		a, c
	ld		[de], a
	
	ret

UpdateBossSpritePos::
	push	hl
	
	inc		de
	ld		a, [de]
	ld		l, a
	dec		de
	
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteBelow
	ld		a, l
	ld		[de], a
	dec		de
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteBelow
	ld		a, l
	ld		[de], a
	dec		de
	call	UpdateSpriteRight
	dec		de
	call	UpdateSpriteRight
	dec		de
	
	pop		hl
	ret
	
INCLUDE "Projects/PieInTheSky/EnemyDeadAnimations.asm"
INCLUDE "Projects/PieInTheSky/EnemyBehaviours.asm"