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

; Disable sprites and playfield, affects A, $FE
API_ENTRYPOINT $e161
DisPFObj:
	LDA ZP_PPUMASK ; Get the existing value
	AND #%11100111 ; clear bits 3 and 4
WritePPUMask:
	STA ZP_PPUMASK ; Write it to RAM
	STA PPUMASK ; Write it to PPUMASK
	RTS

; Enable sprites and playfield, affects A, $FE
API_ENTRYPOINT $e16b
EnPFObj:
	LDA ZP_PPUMASK ; Get the existing value
	ORA #%00011000 ; set bits 3 and 4
	; re-use DisPFObj's implementation of writing the registers to save bytes
	; only six bytes allowed in this function, and JMP would make it 7.
	; use BNE to jump backwards because Z is guaranteed to be 0 (from the
	; non-zero ORA immediate) and that's only 2 bytes
	BNE WritePPUMask

; Disable sprites, affects A, $FE
API_ENTRYPOINT $e171
DisObj:
	LDA ZP_PPUMASK ; Get the existing value
	AND #%11101111 ; clear bit 4
	; Can't trust BNE like EnPFObj, because the result of the preceding AND
	; could be 0. However, we have 7 bytes to play with, so JMP works fine.
	JMP WritePPUMask

; Enable sprites, affects A, $FE
API_ENTRYPOINT $e178
EnObj:
	LDA ZP_PPUMASK ; Get the existing value
	ORA #%00010000 ; set bit 4
	; Branch to DisPFObj's implementation of writing the result to save bytes
	BNE WritePPUMask

; Disable playfield, affects A, $FE
API_ENTRYPOINT $e17e
DisPF:
	LDA ZP_PPUMASK ; Get the existing value
	AND #%11110111 ; clear bit 3
	; Can't trust BNE like EnPFObj, because the result of the preceding AND
	; could be 0. However, we have 7 bytes to play with, so JMP works fine.
	JMP WritePPUMask

; Enable playfield, affects A, $FE
API_ENTRYPOINT $e185
EnPF:
	LDA ZP_PPUMASK ; Get the existing value
	ORA #%00001000 ; set bit 3
	; Branch to DisPFObj's implementation of writing the result to save bytes
	BNE WritePPUMask
