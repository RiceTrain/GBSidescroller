; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height
; byte 5: animation data address

Enemy0Update::
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