; enemy data setup
; byte 1: tile no
; byte 2: health
; byte 3: tile width
; byte 4: tile height

; Lowest enemy behaviour id: 14

;------------------------------------------------------
; setup enemies
; hl = data address of enemy (tile no already set)
;------------------------------------------------------
SetupNewEnemy::
	ld		a, [hli]
	sub		14
	
	cp		0
	jr		z, Enemy0Setup
	cp		1
	jr		z, Enemy0Setup
	
	ret
	
Enemy0Setup::
	ld		a, 3
	ld		[hli], a
	ld		a, 2
	ld		[hli], a
	ld		[hl], a
	
	ret