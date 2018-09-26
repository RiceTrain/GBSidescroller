Player_Dead_Update::
	
	ld		a, [death_timer]
	dec		a
	ld		[death_timer], a
	cp		0
	jp		nz, .animate_explosion

.check_game_over
	ld		a, [lives]
	cp		0
	jr		nz, .reset_player
	
	ld		a, 120
	ld		[game_over_sequence_timer], a
	call	Set_Up_Game_Over_Screen
	jr		.dead_update_end
	
.reset_player
	call	ResetPlayerOnDeath
	jr		.dead_update_end
	
.animate_explosion
	cp		110
	jr		z, PlayerDeathFrame2
	
	cp		100
	jp		z, PlayerDeathFrame3
	
	cp		80
	jr		z, PlayerDeathFrame4
	
	cp		70
	jp		z, PlayerDeathFrame5
	
	cp		60
	jp		z, PlayerDeathFrame6
	
.dead_update_end
	ret
	
ResetPlayerOnDeath::
	call 	InitWorkingVariablesOnDeath
	
	ld		a, 0
	ldh		[SCROLL_BKG_X], a	; background map will start at 0,0
	ldh		[SCROLL_BKG_Y], a
	call	LoadCurrentMapIntoHL
	call	LoadMapToBkg
	
	ld		a, 0
	ld		[level_end_reached], a
	
	call	InitSprites
	
	call 	InitBulletData
	call 	InitEnemyData
	call	InitPlayerData
	
	call 	InitPlayerSprite
	
	call 	ResetScoreToCheckpoint
	call 	UpdateLivesDisplay
	
	call	ResetStatsToCheckpoint
	
	ret
	
InitWorkingVariablesOnDeath::
	ld		a, 0
	ld 		[PixelsScrolled], a
	ld 		[TotalTilesScrolled], a
	ld 		[CurrentBGMapScrollTileX], a
	ld		[CurrentWindowTileX], a
	ld		[CurrentMapBlock], a
	ld		[current_bullet_direction], a
	ld		[ScrollTimer], a
	ld		[joypad_held], a
	ld		[joypad_down], a
	ld		[enemies_destroyed], a
	ld		[items_collected], a
	
	ret
	
ResetStatsToCheckpoint::
	ld		a, [checkpoint_enemies_destroyed]
	ld		[enemies_destroyed], a
	ld		a, [checkpoint_items_collected]
	ld		[items_collected], a
	
	ret
	
PlayerDeathFrame2::
	ld		a, 21
	ld		[spaceshipL_tile], a
	ret
	
PlayerDeathFrame4::
	ld		a, 21
	ld		[spaceshipL_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 4
	ld		[spaceshipL_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 4
	ld		[spaceshipL_ypos], a
	
	ld		a, 0
	ld		[spaceshipR_ypos], a
	ld		[spaceshipR_xpos], a
	ld		[spaceshipLAnim1_ypos], a
	ld		[spaceshipLAnim1_xpos], a
	ld		[spaceshipLAnim2_ypos], a
	ld		[spaceshipLAnim2_xpos], a
	
	ret
	
PlayerDeathFrame5::
	ld		a, 20
	ld		[spaceshipL_tile], a
	ret
	
PlayerDeathFrame6::
	ld		a, 0
	ld		[spaceshipL_xpos], a
	ld		[spaceshipL_ypos], a
	ret

PlayerDeathFrame3::
	ld		a, 22
	ld		[spaceshipL_tile], a
	ld		a, [spaceshipL_xpos]
	sub		4
	ld		[spaceshipL_xpos], a
	ld		a, [spaceshipL_ypos]
	sub		4
	ld		[spaceshipL_ypos], a
	
	ld		a, 22
	ld		[spaceshipR_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 8
	ld		[spaceshipR_xpos], a
	ld		a, [spaceshipL_ypos]
	ld		[spaceshipR_ypos], a
	ld		a, [spaceshipR_flags]
	set 	5, a
	ld		[spaceshipR_flags], a
	
	ld		a, 22
	ld		[spaceshipLAnim1_tile], a
	ld		a, [spaceshipL_xpos]
	add		a, 8
	ld		[spaceshipLAnim1_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 8
	ld		[spaceshipLAnim1_ypos], a
	ld		a, [spaceshipLAnim1_flags]
	set 	5, a
	set 	6, a
	ld		[spaceshipLAnim1_flags], a
	
	ld		a, 22
	ld		[spaceshipLAnim2_tile], a
	ld		a, [spaceshipL_xpos]
	ld		[spaceshipLAnim2_xpos], a
	ld		a, [spaceshipL_ypos]
	add		a, 8
	ld		[spaceshipLAnim2_ypos], a
	ld		a, [spaceshipLAnim2_flags]
	set 	6, a
	ld		[spaceshipLAnim2_flags], a
	
	ret
	
Set_Up_Game_Over_Screen::
	
	ret
	
Game_Over_Update::
	
	ret