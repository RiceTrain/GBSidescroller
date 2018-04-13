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
	jr		z, .enemy_0_update
	
	cp		19
	jr		z, .enemy_1_update

.enemy_0_update
	call	Enemy0Update
	jp		.update_sprite_positions
.enemy_1_update
	call	Enemy1Update
	jp		.update_sprite_positions
	
.update_sprite_positions
	call	UpdateEnemySpritePositions

.end_update
	ret

UpdateDeadEnemy::
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
	jr		z, UpdateDead1x1
	cp		3
	jr		z, UpdateDead2x1
	cp		4
	jr		z, UpdateDead2x2
	
	ret
	
UpdateDead1x1::
	ld		a, [hl]
	dec		a
	ld		[hl], a
	
	cp		15
	jr		z, .frame_2
	cp		5
	jr		z, .frame_3
	cp		0
	jr		z, .frame_4
	
	jp		.update_end
	
.frame_2
	inc		de
	inc		de
	ld		a, 21
	ld		[de], a
	dec		de
	dec		de
	jp		.update_end
.frame_3
	inc		de
	inc		de
	ld		a, 20
	ld		[de], a
	dec		de
	dec		de
	jp		.update_end
.frame_4
	call	CleanupEnemy
	
.update_end
	ret
	
UpdateDead2x1::
	ld		a, [hl]
	dec		a
	ld		[hl], a
	
	cp		20
	jr		z, .frame_2
	cp		10
	jr		z, .frame_3
	cp		0
	jr		z, .frame_4
	
	jp		.update_end
	
.frame_2
	inc		de
	inc		de
	ld		a, 21
	ld		[de], a
	jp		.update_end
.frame_3
	inc		de
	inc		de
	ld		a, 20
	ld		[de], a
	jp		.update_end
.frame_4
	call	CleanupEnemy
	
.update_end
	ret
	
UpdateDead2x2::
	ld		a, [hl]
	dec		a
	ld		[hl], a

	cp		35
	jr		z, .frame_2
	cp		25
	jr		z, .frame_3
	cp		15
	jr		z, .frame_4
	cp		5
	jp		z, .frame_5
	cp		0
	jp		z, .frame_6
	
	jp		.update_end
	
.frame_2
	inc		de
	inc		de
	ld		a, 21
	ld		[de], a
	jp		.update_end
.frame_3
	ld		a, [de]
	sub		4
	ld		[de], a
	ld		b, a
	inc		de
	ld		a, [de]
	sub		4
	ld		[de], a
	ld		c, a
	inc		de
	ld		a, 22
	ld		[de], a
	inc		de
	inc		de
	ld		a, b
	ld		[de], a
	inc 	de
	ld		a, c
	add		8
	ld		[de], a
	inc		de
	ld		a, 22
	ld		[de], a
	inc 	de
	ld		a, 0
	set 	5, a
	ld		[de], a
	inc 	de
	ld		a, b
	add		8
	ld		[de], a
	inc 	de
	ld		a, c
	add		8
	ld		[de], a
	inc		de
	ld		a, 22
	ld		[de], a
	inc		de
	ld		a, 0
	set 	5, a
	set 	6, a
	ld		[de], a
	inc		de
	ld		a, b
	add		8
	ld		[de], a
	inc		de
	ld		a, c
	ld		[de], a
	inc		de
	ld		a, 22
	ld		[de], a
	inc		de
	ld		a, 0
	set 	6, a
	ld		[de], a
	jp		.update_end
.frame_4
	ld		a, [de]
	add		4
	ld		[de], a
	inc		de
	ld		a, [de]
	add		4
	ld		[de], a
	inc		de
	ld		a, 21
	ld		[de], a
	inc		de
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
	ld		[de], a
	jp		.update_end
.frame_5
	inc		de
	inc		de
	ld		a, 20
	ld		[de], a
	jp		.update_end
.frame_6
	call	CleanupEnemy
	
.update_end
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
	
.update_2x2
	call	Update2x2
	jp		.end_update
	
.update_2x1
	ld		a, c
	cp		2
	jr		z, Update2x1
	jr		nz, Update1x2
	
.end_update
	ret

Update2x1::
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

Update1x2::
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
	call	Update2x1
	dec		de
	call	Update1x2
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
	
INCLUDE "Projects/PieInTheSky/EnemyBehaviours.asm"