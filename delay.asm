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

; Fritters away 131 cycles. (NesDev Wiki says 132 cycles, but there's no way
; to waste that amount in just 10 bytes of instructions without clobbering
; something.)
API_ENTRYPOINT $e149
Delay131:
	CLC ; 1 byte, 2 cycles
	PHA ; 1 byte, 3 cycles
	LDA #$E9 ; 2 bytes, 2 cycles
	; now waste 114 cycles
	@loop:
		ADC #1 ; 2 bytes, 2 cycles
		BCC @loop ; 2 bytes, 3 cycles except for last time when it's 2
	PLA ; 1 byte, 4 cycles
	RTS ; 1 byte, 6 cycles

; Delays roughly Y ms, affects X, Y
; If y == 0, then delay 256 ms
API_ENTRYPOINT $e153
Delayms:
	; Every cycle is 1/1789.7725 ms. Each iteration of the outer loop spins 1790 cycles to delay 1 ms
	LDX #255 ; 2 bytes, 2 cycles
	; first inner loop burns 1274 cycles
	@inner1:
		DEX ; 1 byte, 2 cycles
		BNE @inner1 ; 2 bytes, 3 cycles except for the last time when it's 2
	LDX #102 ; 2 bytes, 2 cycles
	; second inner loop burns 509 cycles (ideal would be 507)
	@inner2:
		DEX ; 1 byte, 2 cycles
		BNE @inner2 ; 2 bytes, 3 cycles except for the last time when it's 2
	DEY ; 1 byte, 2 cycles
	BNE Delayms ; 2 bytes, 3 cycles except for the last time when it's 2
	RTS ; 1 byte, 6 cycles
