;-----------------------------------------------------------------------
; Plays sound effects
;-----------------------------------------------------------------------
InitSoundChannels::
;	ld		a, %11111111
;	ld		[AUD_VOLUME], a
;	ld		a, %11111111
;	ld		[AUD_TERM], a
;	ld		a, %11110001
;	ld		[AUD_ENA], a

	ld      de,GameTheme_data
    ld      bc,BANK(GameTheme_data)
    ld      a,$05
    call    gbt_play ; Play song
	
	ret
	
PlayBulletSound::
	push	hl
	ld		hl, BulletSoundData
	call	PlaySoundOnChannelOne
	pop		hl
	
	ret
	
PlaySoundOnChannelOne::
	ld		a, [hli]
	ldh		[AUD_1_SWEEP], a
	ld		a, [hli]
	ldh		[AUD_1_LENGTH], a
	ld		a, [hli]
	ldh		[AUD_1_ENV], a
	ld		a, [hli]
	ldh		[AUD_1_LOW], a
	ld		a, [hl]
	ldh		[AUD_1_HIGH], a
	ret
	
PlayEnemyExplosionSound::
	push	hl
	ld		hl, EnemyExplosionSoundData
	call	PlaySoundOnChannelFour
	pop		hl
	
	ret
	
PlayPlayerBossExplosionSound::
	push	hl
	ld		hl, PlayerExplosionSoundData
	call	PlaySoundOnChannelFour
	pop		hl
	
	ret
	
PlayEnemyHitSound::
	push	hl
	ld		hl, BossHitSoundData
	call	PlaySoundOnChannelFour
	pop		hl
	
	ret
	
PlaySoundOnChannelFour::
	ld		a, [hli]
	ldh		[AUD_4_LENGTH], a
	ld		a, [hli]
	ldh		[AUD_4_ENV], a
	ld		a, [hli]
	ldh		[AUD_4_POLY], a
	ld		a, [hl]
	ldh		[AUD_4_GO], a
	ret
	
INCLUDE "Projects/PieInTheSky/Data/SoundEffects.z80"
INCLUDE "Projects/PieInTheSky/gbt_player.asm"
INCLUDE "Projects/PieInTheSky/gbt_player_bank1.asm"