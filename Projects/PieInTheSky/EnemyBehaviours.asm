; Lowest enemy behaviour id: 14

;------------------------------------------------------
; update enemy behaviour
; de = enemy sprite address
; hl = data address of enemy
;------------------------------------------------------
UpdateEnemyBehaviour::
	call 	GetEnemyIndex
	cp		0
	jr		z, Enemy0Update
	
	ld		a, [enemy_updated_flag]
	cp		1
	jr		z, .enemy_updated
	
	call 	GetEnemyIndex
	cp		1
	jr		z, Enemy1Update
	
.enemy_updated
	ld		a, 0
	ld		[enemy_updated_flag], a
	ret

GetEnemyIndex::
	ld		a, [hl]
	sub		14
	ret
	
SetEnemyUpdatedFlag::
	ld		a, 1
	ld		[enemy_updated_flag], a
	ret
	
Enemy0Update::
	inc		de
	ld		a, [de]
	dec		a
	ld		[de], a

	call SetEnemyUpdatedFlag
	ret
	
Enemy1Update::
	ld		a, [de]
	dec		a
	ld		[de], a
	
	call SetEnemyUpdatedFlag
	ret