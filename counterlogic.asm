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

; Decrement several counters in Zeropage. The first counter is a decimal
; counter 9 -> 8 -> 7 -> ... -> 1 -> 0 -> 9 -> ... Counters 1...A are simply
; decremented and stays at 0. Counters A+1...Y are decremented when the first
; counter does a 0 -> 9 transition, and stays at 0.
; Parameters: A, Y = end Zeropage address of counters, X = start zeropage address of counters
; Affects: A, X, $00
API_ENTRYPOINT $e9d3
CounterLogic:
	STX $00 ; 2 bytes
	DEC 0,X ; 2 bytes
	; if negative, set the first counter to 9, otherwise continue
	BPL @countersToA ; 2 bytes
	LDA #$09 ; 2 bytes
	STA 0,X ; 2 bytes
	; Do the A+1...Y counters now, since we know that the first counter rolled over
@countersAplus1toY:
	; there's no zp,y addressing mode, only zp,x so copy Y to X through A
	TYA ; 1 byte
@countersToA:
	TAX ; 1 byte
@loop:
	LDA 0,X ; 2 bytes
	; skip counters that are already 0
	BEQ @looptest ; 2 bytes
	DEC 0,X ; 2 bytes
@looptest:
	DEX ; 1 byte
	CPX $00 ; 2 bytes
	BNE @loop ; 2 bytes
	RTS ; 1 byte
