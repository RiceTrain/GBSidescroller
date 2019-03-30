; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address
; byte 6: score value
; byte 7-9: misc

PatternEnemyUpdate::
	inc		de
	ld		a, [de]
	dec		a
	ld		[de], a
	dec		de
	
	ret
	
Enemy1Update::
	ld		a, [de]
	dec		a
	ld		[de], a
	
	ret