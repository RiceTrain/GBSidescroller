;-----------------------------------------------------------------------
; Plays sound effects
;-----------------------------------------------------------------------
InitSoundChannels::
	;ld		a, %11111111
	;ld		[AUD_VOLUME], a
	;ld		a, %11111111
	;ld		[AUD_TERM], a
	;ld		a, %11110001
	;ld		[AUD_ENA], a

	ret
PlayBulletSound::
	push	hl
	push	de
	push	bc
	
	ld		hl, BulletSoundData
	ld		a, [hli]
	ldh		[AUD_4_LENGTH], a
	ld		a, [hli]
	ldh		[AUD_4_ENV], a
	ld		a, [hli]
	ldh		[AUD_4_POLY], a
	ld		a, [hl]
	ldh		[AUD_4_GO], a
	
	pop		bc
	pop		de
	pop		hl
	
	ret
	
INCLUDE "Projects/PieInTheSky/Data/SoundEffects.z80"
	