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

; Write buffers from the VRAM Write Buffer, starting at $302, to VRAM. Each
; buffer is described and preceded by a 3 byte header.
; The first two bytes specify the destination VRAM address.
; - To mark the end of the list of buffers, put a value >= $80 instead in the
;   first byte.
; - The original version checks if each structure's address STARTS in the
;   palette (addr >= $3F00), then it sets PPUADDR to $3F00 followed by $0000
;   after copying that structure. It appears to be an attempt to prevent the
;   PPU from drawing the colors of the palette to the screen, AKA, the
;   "background palette hack," which occurs whenever rendering is off and the
;   PPUADDR is somewhere in the palette. (FWIW, rendering is likely to be off
;   when this function is called.)
;   To reliably prevent the palette from being drawn to the screen, what this
;   implementation does instead is to check whether the address of just the
;   last structure PLUS its length is in the $3F00-$3FFF area (or the mirror at
;   $7F00-$7FFF).
; The third byte contains the length of the buffer.
; - There's no check for 0-length buffers. Specifying a length of 0 will cause
;   a buffer overflow.
; Before returning, the write buffer is cleared (0 written to $301, $80 written
; to $302.)
; Affects: A, X, Y, $02, $03, $04, $301, $302
API_ENTRYPOINT $e86a
WriteVRAMBuffers:
	LDA ZP_PPUCTRL
	AND #%11111011 ; Address increment of 1
	STA PPUCTRL
	STA ZP_PPUCTRL
	LDA PPUSTATUS ; clear PPUADDR latch
	LDY #0 ; Start at the beginning of $302
@structure:
	LDA $302,Y  ; load high byte of destination PPU Address
	BMI @done   ; an "opcode" of $80 or more marks the end of the list
	STA $03     ; save the address (little endian) so we can check later for PPUADDR in the palette
	STA PPUADDR ; set the high byte of the initial address
	INY
	LDA $302,Y  ; load low byte of destination PPU address
	STA $02     ; save the low byte of the address (little endian)
	STA PPUADDR ; set the low byte of the initial address
	INY
	LDX $302,Y  ; load buffer length from third byte
	STX $04     ; save the length so we can check later for PPUADDR in the palette
	INY
@loop:
	LDA $302,Y
	STA PPUDATA
	INY
	DEX
	BNE @loop
	BEQ @structure ; this structure is done, so move onto the next one
@done:
	STA $302 ; write the $80 "opcode" to the first structure's address to clear the list
	LDA #0   ; clear the write buffer, i.e., move the read buffer to the beginning
	STA $301
	; Finally, clear PPUADDR if it's currently in the palette
	JSR PreventPalettePpuAddr
	RTS

; Read individual bytes from VRAM to the VRAMBuffer. Each byte in the buffer is
; preceded by the source address - (1|32) in VRAM; in other words, it takes 3
; bytes of space in the VRAM Buffer for every byte to read, and the byte
; written to the buffer comes from 1 byte or 32 bytes LATER than the specified
; address, as this function does NOT change the address increment mode.
; Affects A, X, Y
; Parameters: X = start address of read buffer, Y = # of bytes to read
API_ENTRYPOINT $e8b3
ReadIndividualVRAMBytes:
	LDA PPUSTATUS ; clear PPUADDR latch
@loop:
	LDA $300,X    ; high address byte
	STA PPUADDR
	INX
	LDA $300,X    ; load low address byte
	STA PPUADDR
	INX
	LDA PPUDATA   ; read (and throw away) buffered byte from VRAM
	LDA PPUDATA   ; read buffered byte from VRAM
	STA $300,X
	INX
	DEY
	BNE @loop
	RTS
