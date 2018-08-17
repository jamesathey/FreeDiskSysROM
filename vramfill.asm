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

; memset for VRAM.
; If A < $20, it fills pattern table data with the value in X for 16 * Y tiles,
; or Y * 256 bytes.
; If A >= $20, it fills the corresponding nametable with the value in X and
; attribute table with the value in Y.
; Parameters: A = High VRAM Address (aka tile row #), X = Fill value, Y = # of tile rows OR attribute fill data
; Affects: A, $00, $01, $02, $FF (aka PPUCTRL)
API_ENTRYPOINT $ea84
VRAMFill:
    STY $02 ; preserve Y so it can be restored later
	; every write to PPUADDR needs to ensure that the PPUADDR latch is clear
	; one nice feature of TOP is that it reads without clobbering anything
	TOP PPUSTATUS
	; set the address
	STA PPUADDR
	LDA #0
	STA PPUADDR
	; set the correct VRAM increment mode of 1
	LDA ZP_PPUCTRL
	AND #%11111011
	STA PPUCTRL
	STA ZP_PPUCTRL
	; pattern or nametable fill?
	CMP #$20
	BCS @VramNametableFill
@VramPatternFill:
	CLC
	; The address has been loaded, so now we can use A as a counter
	; 16 tiles in a row, 16 bytes per tile = 256 bytes to write per row
	LDA #0
@tile:
	STX PPUDATA
	ADC #1
	BCC @tile
	DEY
	BNE @VramPatternFill

    ; restore Y (X never changed)
    LDY $02
	RTS

@VramNametableFill:
	; fill the nametable with X for 960 bytes, or 4 * 240 bytes
    STX $01 ; preserve X so it can be restored later
	TXA
	LDX #4
@quarterNT
	LDY #240
@name:
	STA PPUDATA
	DEY
	BNE @name
	DEX
	BNE @quarterNT
	; restore the attr file value in Y
	LDY $02
	; then fill the attributes with Y for 64 bytes
	LDX #64
@attr:
	STY PPUDATA
	DEX
	BNE @attr

    ; restore X (Y is already restored)
    LDX $01
	RTS
