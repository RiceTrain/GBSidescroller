; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address
; byte 6: misc
; byte 7: misc
; byte 8: spawn placement info

Enemy1x1SpriteSetup::
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret

Enemy2x1SpriteSetup::
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret
	
Enemy1x2SpriteSetup::
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret
	
Enemy2x2SpriteSetup::
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ret
	
BossSpriteSetup::
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		16
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	set 	6, a
	ld		[de], a
	
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	8
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		16
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	
	ld		a, [new_enemy_y_pos]
	add 	16
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	ld		[de], a
	inc		de
	ld		a, [new_enemy_y_pos]
	add 	16
	ld		[de], a
	inc		de
	ld		a, [new_enemy_x_pos]
	add		8
	ld		[de], a
	inc		de
	ld		a, [hli]
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
	ld		a, [new_enemy_x_pos]
	add		16
	ld		[de], a
	inc		de
	ld		a, [hli]
	ld		[de], a
	inc		de
	ld		a, 0
	set 	6, a
	ld		[de], a
	
	ret