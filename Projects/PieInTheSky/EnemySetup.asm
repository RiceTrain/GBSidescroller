; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address

Enemy0Data::
	ld		a, 3
	ld		[hli], a
	ld		a, 2
	ld		[hli], a
	ld		a, 1
	ld		[hli], a
	
	ret

Enemy0AnimSprite::
	inc		de
	ld		a, 30
	ld		[de], a
	inc		de
	
	ld		a, 18
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, 19
	ld		[de], a
	inc		de
	ld		a, 1
	ld		[de], a
	
	call	GetEmptySpriteAddress
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 192
	ld		[de], a
	inc		de
	ld		a, 18
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 200
	ld		[de], a
	inc		de
	ld		a, 19
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret
	
Enemy1Data::
	ld		a, 3
	ld		[hli], a
	ld		a, 1
	ld		[hli], a
	ld		[hli], a
	
	ret

Enemy1AnimSprite::
	inc		de
	ld		a, 70
	ld		[de], a
	inc		de
	ld		a, 19
	ld		[de], a
	inc		de
	ld		a, 18
	ld		[de], a
	
	call	GetEmptySpriteAddress
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 192
	ld		[de], a
	inc		de
	ld		a, 19
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret
	
Boss0Data::
	ld		a, 15
	ld		[hli], a
	ld		a, 3
	ld		[hli], a
	ld		[hli], a
	
	ret

Boss0AnimSprite::
	inc		de
	ld		a, 10
	ld		[de], a
	inc		de
	
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	inc		de
	
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	
	call	GetEmptySpriteAddress
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 192
	ld		[de], a
	inc		de
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 200
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, 208
	ld		[de], a
	inc		de
	ld		a, 23
	ld		[de], a
	inc		de
	ld		a, 0
	set 	6, a
	ld		[de], a
	
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, 192
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, 200
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, 208
	ld		[de], a
	inc		de
	ld		a, 26
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ld		a, [new_enemy_y_pos]
	add 	16
	ld		[de], a
	inc		de
	ld		a, 192
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	16
	ld		[de], a
	inc		de
	ld		a, 200
	ld		[de], a
	inc		de
	ld		a, 24
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	set 	5, a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	16
	ld		[de], a
	inc		de
	ld		a, 208
	ld		[de], a
	inc		de
	ld		a, 25
	ld		[de], a
	inc		de
	ld		a, 0
	set 	6, a
	ld		[de], a
	
	ret