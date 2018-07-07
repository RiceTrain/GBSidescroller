;-----------------------------------------------------------------------
; read the joypad
;
; output:
; 		This loads two variables:
;			joypad_held		- what buttons are currently held
;			joypad_down		- what buttons went down since last joypad read
;-----------------------------------------------------------------------
ReadJoypad::
	; get the d-pad buttons
	ld		a, PAD_PORT_DPAD		; select d-pad
	ldh		[JOYPAD_REGISTER], a	; send it to the joypad
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]	; get the result back (takes a few cycles)
	cpl			; bit-flip the result
	and		PAD_OUTPUT_MASK		; mask out the output bits
	swap	a					; put the d-pad button results to top nibble
	ld		b, a				; and store it

	; get A / B / SELECT / START buttons
	ld		a, PAD_PORT_BUTTONS		; select buttons
	ldh		[JOYPAD_REGISTER], a	; send it to the joypad
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]
	ldh		a, [JOYPAD_REGISTER]	; get the result back (takes even more cycles?)
	cpl			; bit-flip the result
	and		PAD_OUTPUT_MASK		; mask out the output bits
	or		b					; add it to the other button bits
	ld		b, a			; put it back in c

	; calculate the buttons that went down since last joypad read
	ld		a, [joypad_held]	; grab last button bits
	cpl							; invert them
	and		b					; combine the bits with current bits
	ld		[joypad_down], a	; store just-went-down button bits

	ld		a, b
	ld      [joypad_held], a	; store the held down button bits

	ld		a, $30       ; reset joypad
    ldh		[JOYPAD_REGISTER],A

	ret			; done
	