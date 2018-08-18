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

; Shift-register based random number generator, normally takes 2 bytes (using
; more won't affect random sequence). On reset the program is supposed to
; write some non-zero values here (BIOS uses writes $d0, $d0), and call this
; routine several times before the data is actually random. Each call of this
; routine will shift the bytes right.
;
; Algorithm:
; 1. exclusive-OR the bit 1s of [X] and [X+1].
; 2. Rotate [X] to the right, rotating a 1 into the MSB if step 1 was non-zero.
; 3. Rotate each of the remaining bytes [X+1] ... [X+(Y-1)] to the right,
;    carrying the LSB of the previous byte into the MSB of the next.
;
; Parameters: X = Zero Page address where the random bytes are placed
;             Y = # of shift register bytes (normally 2)
; Affects: A, X, Y, $00
API_ENTRYPOINT $e9b1
Random:
	LDA $00,X
	AND #$02
	STA $00
	LDA $01,X
	AND #$02
	EOR $00
; rotate a 1 into the first byte if the XOR was non-zero
	SEC
	BNE @shifter
; it was 0, so rotate a 0 into the first byte
	CLC
@shifter:
	ROR $00,X
	INX
	DEY
	BNE @shifter
	RTS
