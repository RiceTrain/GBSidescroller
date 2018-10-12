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
	ld		hl, MAP_MEM_LOC_1
	call 	UpdateScoreDisplay
.score_adding_finished
	pop		bc
	pop 	de
	pop		hl
	
	ret
	
ResetScoreToCheckpoint::
	call	DisplayMinScore
	
	ld		a, 0
	ld		[current_score], a
	ld		a, 0
	ld		[score_tracker_lower], a
	ld		a, 0
	ld		[score_tracker_higher], a
	
	ld		a, [checkpoint_score_tracker_lower]
	cp 		0
	jr		z, .add_current_score
	
	ld		c, a
	ld		a, [checkpoint_score_tracker_higher]
	ld		b, a
	
.add_score_loop
	ld		a, $ff
	call	AddAToCurrentScore
	dec		c
	jr		nz, .add_score_loop
	ld		c, $ff
	dec		b
	jr		z, .add_score_loop
	
.add_current_score
	ld		a, [checkpoint_current_score]
	call	AddAToCurrentScore
	
	ret
	
SaveHiScore::
	ld		a, [score_tracker_higher]
	ld		b, a
	ld		a, [high_score_tracker_higher]
	cp		b
	jr		c, .save_high_score
	jr		nz, .end_saving
	
	ld		a, [score_tracker_lower]
	ld		b, a
	ld		a, [high_score_tracker_lower]
	cp		b
	jr		c, .save_high_score
	jr		nz, .end_saving
	
	ld		a, [current_score]
	ld		b, a
	ld		a, [high_current_score]
	cp		b
	jr		c, .save_high_score
	jr		.end_saving
	
.save_high_score
	ld		a, [current_score]
	ld		[high_current_score], a
	ld		a, [score_tracker_lower]
	ld		[high_score_tracker_lower], a
	ld		a, [score_tracker_higher]
	ld		[high_score_tracker_higher], a
	
.end_saving
	ret