;-----------------------------------------------------------------------
; Plays sound effects
;-----------------------------------------------------------------------
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
	