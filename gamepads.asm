; FreeDiskSysROM
; Copyright (c) 2018 James Athey
;
; This program is free software: you can redistribute it and/or modify it under
; the terms of the GNU Lesser General Public License version 3 as published by
; the Free Software Foundation.
;
; This program is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
; details.
;
; You should have received a copy of the GNU Lesser General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

; Read hard-wired Famicom joypads.
; Returns: $F5 = Joypad #1 data, $F6 = Joypad #2 data, $00 = Expansion #1 data, $01 = Expansion #2 data
; Affects: A, X, $00, $01, $F5, $F6, $FB
API_ENTRYPOINT $e9eb
ReadPads:
	; If this is being called to also read expansion port pads, bit 1 of $FB
	; will be 1, otherwise it will be 0. To strobe the controllers in either
	; case, just set the 1s bit on the value in $FB, then clear it to read.
	LDX ZP_JOYPAD1
	INX ; now X[0] is 1, assuming that no other function will set that bit to 1
	; While the strobe bit is set, buttons will be continuously reloaded.
	; This means that reading from JOYPAD1 will only return the state of the
	; first button: button A.
	STX JOYPAD1
	DEX ; now X[0] is 0
	; By storing bit 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
	; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
	STX JOYPAD1
	LDX #8 ; 8 bits to load
@loop:
	LDA JOYPAD1
	LSR A ; if bit 0 was a 1, the carry flag will be set
	ROR $F5 ; rotate the carry flag's value into $F5, where the joypad #1 data lives
	LSR A ; bit 0 was already shifted out, now shift bit 1 into the carry flag
	ROR $00 ; rotate the carry flag's value into $00, where the expansion #1 data lives
	LDA JOYPAD2
	LSR A ; if bit 0 was a 1, the carry flag will be set
	ROR $F6 ; rotate the carry flag's value into $F6, where the joypad #2 data lives
	LSR A ; bit 0 was already shifted out, now shift bit 1 into the carry flag
	ROR $01 ; rotate the carry flag's value into $01, where the expansion #2 data lives
	DEX
	BNE @loop
	RTS

; Combine the reports from the built-in and expansion gamepads by OR'ing them
; together, storing them in the built-in gamepads' variables ($F5 and $F6)
OrPads:
	LDA $00
	ORA $F5
	STA $F5
	LDA $01
	ORA $F6
	STA $F6
	RTS

; Read hard-wired Famicom joypads, and detect up->down button transitions
; Returns: $f5 = Joypad #1 up->down transitions, $f6 = Joypad #2 up->down transitions $f7 = Joypad #1 data, $f8 = Joypad #2 data
; Affects: A, X, Y, $00, $01, $F5, $F6, $F7, $F8
API_ENTRYPOINT $ea1a
ReadDownPads:
	JSR ReadPads
	BEQ DetectUpToDownTransitions; skip over ReadOrDownPads

; Read both hard-wired Famicom and expansion port joypads (OR'd together), and detect up->down
; button transitions.
; Returns: $f5 = Joypad #1 up->down transitions, $f6 = Joypad #2 up->down transitions $f7 = Joypad #1 data, $f8 = Joypad #2 data
; Affects: A, X, Y, $00, $01, $F5, $F6, $F7, $F8
API_ENTRYPOINT $ea1f
ReadOrDownPads:
	JSR ReadPads
	JSR OrPads
	; fall through to detection

DetectUpToDownTransitions:
	LDX #1 ; handle pad #2 first
DetectUpToDownOnePad:
	LDA $F5,X ; load current joypad state
	TAY ; preserve the current state in Y
	EOR $F7,X ; exclusive-OR between previous and current state says which buttons have changed
	AND $F5,X ; AND of that with current state says which buttons have changed to down
	STA $F5,X ; save up-down transitions
	STY $F7,X ; overwrite previous state with current state via temporary
	DEX
	BPL DetectUpToDownOnePad ; when X underflows to -127, this branch will not be taken
	RTS

; Read hard-wired Famicom joypads, and detect up->down button transitions. Data
; is read until two consecutive read matches to work around the DMC reading
; glitches.
; Returns: $f5 = Joypad #1 up->down transitions, $f6 = Joypad #2 up->down transitions $f7 = Joypad #1 data, $f8 = Joypad #2 data
; Affects: A, X, Y, $00, $01, $F5, $F6, $F7, $F8
API_ENTRYPOINT $ea36
ReadDownVerifyPads:
	JSR ReadPads
@remember:
	LDA $F5 ; get controller #1's value
	PHA ; store controller #1's value on the stack
	LDY $F6 ; ReadPads does not touch Y, so controller #2's value can be preserved there
	JSR ReadPads
	PLA
	EOR $F5 ; do the previous and current reads of JOYPAD1 match?
	BNE @remember ; if they don't match, read again
	CPY $F6 ; do the previous and current reads of JOYPAD2 match?
	BNE @remember ; if they don't match, read again
	BEQ DetectUpToDownTransitions ; if they do match, branch (using BEQ which we know will work) to DetectUpToDownTransitions

; Read both hard-wired Famicom and expansion port joypads and detect up->down
; button transitions. Data is read until two consecutive read matches to work
; around the DMC reading glitches.
; Returns: $f5 = Joypad #1 up->down transitions, $f6 = Joypad #2 up->down transitions $f7 = Joypad #1 data, $f8 = Joypad #2 data
; Affects: A, X, Y, $00, $01, $F5, $F6, $F7, $F8
API_ENTRYPOINT $ea4c
ReadOrDownVerifyPads:
	JSR ReadPads
@remember:
	LDA $F5 ; get controller #1's value
	PHA ; store controller #1's value on the stack
	LDY $F6 ; ReadPads does not touch Y, so controller #2's value can be preserved there
	JSR ReadPads
	PLA
	EOR $F5 ; do the previous and current reads of JOYPAD1 match?
	BNE @remember ; if they don't match, read again
	CPY $F6 ; do the previous and current reads of JOYPAD2 match?
	BNE @remember ; if they don't match, read again
	JSR OrPads ; OR the built-in and expansion pads together
VerifyDownPads:
	JSR DetectUpToDownTransitions
	RTS

; Read both hard-wired Famicom and expansion port joypad, but store their data
; separately instead of ORing them together like the other routines do. This
; routine is NOT DMC fortified.
; Returns: $f1-$f4 = joypad data, $f5-$f8 = up-to-down transitions in the order : Pad1, Pad2, Expansion1, Expansion2
; Affects: A, X, Y, $00, $01, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8
API_ENTRYPOINT $ea68
ReadDownExpPads:
	JSR ReadPads
	; exp1 and exp2 are in $00 and $01, so copy them to their destinations
	LDA $00
	STA $F7
	LDA $01
	STA $F8
	LDX #3 ; handle expansion pad #2 first
@DetectUpToDownOnePadExp:
	LDA $F5,X ; load current joypad state
	TAY ; preserve the current state in Y
	EOR $F1,X ; exclusive-OR between previous and current state says which buttons have changed
	AND $F5,X ; AND of that with current state says which buttons have changed to down
	STA $F5,X ; save up-down transitions
	STY $F1,X ; overwrite previous state with current state via temporary
	DEX ; handle pad #1 next (offset 0), otherwise return
	BPL @DetectUpToDownOnePadExp ; when X underflows to -127, this branch will not be taken
	RTS
