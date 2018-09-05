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

; $eb66 is the beginning of the LoadTileset section of the ROM, but the
; entrypoint isn't until $ebaf
API_ENTRYPOINT $eb66
AdvanceTileBy8:
    LDA #8
AdvanceTileByA:
    LDY #0  ; reset the buffer index
    PHP     ; we need to preserve the carry bit - it has the transfer direction
    CLC
    ADC $00
    STA $00
    LDA #0
    ADC $01
    STA $01
    PLP     ; restore the carry bit
    DEC $03
    RTS

Fill8:
    LDX #8
    LDA $04
@loop:
    BCC @write8
    LDA PPUDATA   ; advance PPUADDR 1 byte
    BCS @next
@write8:
    STA PPUDATA
@next:
    DEX
    BNE @loop
    RTS

Copy8:
    LDX #8
@loop:
    BCC @write8
    LDA PPUDATA
    STA ($00),Y
    BCS @next
@write8:
    LDA ($00),Y
    STA PPUDATA
@next:
    INY
    DEX
    BNE @loop
    RTS

Write8XOR:
    LDX #8
@loop:
    LDA ($00),Y
    EOR $04
    STA PPUDATA
    INY
    DEX
    BNE @loop
    RTS

; This routine can read and write 2BP and 1BP tilesets to/from VRAM.
; The flags parameters are as follows:
;
; 7  bit  0
; ---------
; AAAA MMIT
; |||| ||||
; |||| |||+- Fill bit
; |||| ||+-- Transfer direction (0 = Write tiles, 1 = Read tiles)
; |||| ++--- Bitplane type (see below)
; ++++------ Low VRAM Address (aka tile # within a row)
;
;         1st bitplane	2nd bitplane     Description
;         -----------	-----------      -----------
;     0:  data           data+8           Normal 2-bitplane graphics
;     1:  data           fill bit         Single bitplane graphics. Fill bit clear : Use colors 0&1  Fill bit set : Use colors 2&3
;     2:  fill bit       data             Single bitplane graphics. Fill bit clear : Use colors 0&2  Fill bit set : Use colors 1&3
;     3:  data^fill bit  data             Single bitplane graphics. Fill bit clear : Use colors 0&3  Fill bit set : Use colors 1&2
; This makes it possible for single bitplane tiles to take all possible color
; schemes when they end up in VRAM. However, it is not possible to (natively)
; load single bitplane graphics directly from the disk into VRAM; it should be
; loaded into PRG-RAM before transferring the data into VRAM. In read mode, all
; non "data" bitplanes are replaced by dummy reads. Also, mode 3 ONLY works in
; write mode!
; Parameters: A = Low VRAM Address & Flags, Y = Hi VRAM Address, X = # of tiles to transfer to/from VRAM, Direct Pointer = CPU address
; Affects: A, X, Y, $00, $01, $02, $03, $04, $05, $06
API_ENTRYPOINT $ebaf
LoadTileset:
    TOP PPUSTATUS ; clear PPU address latch
    STY PPUADDR   ; set high byte of PPU address
    STA $02       ; store flags until we need them
    AND #$F0
    STA PPUADDR   ; set low byte of VRAM address
    STX $03       ; store length
    JSR FetchDirectPtr

    LDA ZP_PPUCTRL
    AND #%11111011 ; set increment mode to 1
    STA ZP_PPUCTRL
    STA PPUCTRL

    LDA #0
    TAY            ; Y = 0, start at beginning of buffer
    LSR $02
    BCC @fillClear
    LDA #$FF
@fillClear:
    STA $04        ; save fill byte

    LSR $02        ; shift the transfer direction into the carry flag and keep it there
    BCC @writeMode
    LDA PPUDATA    ; read and throw away a byte, to prime the PPU read buffer
@writeMode:
    LDA #%00000011 ; mask the lowest two bits, where the mode has been shifted to
    AND $02
    BEQ @mode0
    CMP #2
    BEQ @mode2 ; if (mode == 2)
    BCC @mode1 ; if (mode < 2)

@mode3:
    JSR Write8XOR
    LDY #0         ; Read the same data
    JSR Copy8
    JSR AdvanceTileBy8
    BNE @mode3
    RTS

@mode0:
    JSR Copy8
    JSR Copy8
    LDA #16
    JSR AdvanceTileByA
    BNE @mode0
    RTS

@mode1:
    JSR Copy8
    JSR Fill8
    JSR AdvanceTileBy8
    BNE @mode1
    RTS

@mode2:
    JSR Fill8
    JSR Copy8
    JSR AdvanceTileBy8
    BNE @mode2
	RTS
