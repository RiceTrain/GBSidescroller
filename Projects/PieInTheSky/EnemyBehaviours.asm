; Lowest enemy behaviour id: 14

;------------------------------------------------------
; update enemy behaviour
; de = enemy sprite address
; hl = data address of enemy
;------------------------------------------------------
UpdateEnemyBehaviour::
	ld		a, [hl]
	sub		14
	
	cp		0
	jr		z, Enemy0Update
	
	cp		1
	jr		z, Enemy1Update
	
	ret
	
Enemy0Update::
	inc		de
	ld		a, [de]
	dec		a
	ld		[de], a
	
	ret
	
Enemy1Update::
	ld		a, [de]
	dec		a
	ld		[de], a
	
	ret