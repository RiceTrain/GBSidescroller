AddEnemyScore::
	ld		a, [current_enemy_score_value]
	
	call	AddAToCurrentScore
	ret
	
AddAToCurrentScore::
	push	hl
	push	de
	push	bc
	
	ld		b, a
	
	ld		a, [score_tracker_higher]
	cp		1 ;This is the maximum higher score. 1 = 65,025 pts
	jr		nz, .continue_adding_score
	ld		a, [score_tracker_lower]
	cp		136 ;This is the maximum lower score. 136 = 34,680 pts
	jr		nz, .continue_adding_score
	ld		a, [current_score]
	cp		40 ;if above checks pass, then 40+ in current score means 100,000+. Max reached!
	jr		z, .display_max_score
	jr		nc, .display_max_score
	
.continue_adding_score
	ld		a, [current_score]
	add		a, b
	ld		[current_score], a
	jr		nc, .update_score_display
	
	;if adding has carried over, record result in trackers
	ld		a, [score_tracker_lower]
	ld		l, a
	ld		a, [score_tracker_higher]
	ld		h, a
	
	ld		d, 0
	ld		e, 1
	add		hl, de
	
	ld		a, l
	ld		[score_tracker_lower], a
	ld		a, h
	ld		[score_tracker_higher], a

	jr		.update_score_display
	
.display_max_score
	call 	DisplayMaxScore
	jr		.score_adding_finished
.update_score_display
	call 	UpdateScoreDisplay
.score_adding_finished
	pop		bc
	pop 	de
	pop		hl
	
	ret