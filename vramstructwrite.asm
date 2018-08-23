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

; Affects: A, X, Y, $00, $01, $02, $03, $04, $FF
; Parameters: Direct Pointer to VRAM buffer to be written
API_ENTRYPOINT $e7bb
VRAMStructWrite:
	LDA PPUSTATUS ; clear PPUADDR latch
	JSR FetchDirectPtr ; start of the buffer is now in ($00)
@buffer:
	LDY #0
@structure:
	LDA ($00),Y ; load high byte of destination PPU Address
	BMI @done   ; >= $80 is the finish opcode
	CMP #$4C    ; "call" opcode
	BEQ @call
	CMP #$60    ; "return" opcode
	BEQ @return
	STA $03     ; save the high byte of the address (little endian)
	STA PPUADDR ; set the high byte of the initial address 
	INY
	
	LDA ($00),Y ; load low byte of destination PPU address
	STA $02     ; save the low byte of the address (little endian)
	STA PPUADDR ; set the low byte of the initial address
	INY

	LDX ($00),Y ; load buffer length and flags from third byte
	TXA
	AND #%00111111 ; if bits 0-5 are all zero (length of 0), then the length is really 64
	BNE @savelength
	LDA #64
@savelength:
	STA $04     ; save the length so we can check later for PPUADDR in the palette
	INY
	TXA
	BMI @incr32 ; if bit 7 set, increment mode is 32
	LDA ZP_PPUCTRL
	AND #%11111011 ; Address increment of 1
	JMP @setincr
@incr32:
	LDA ZP_PPUCTRL
	ORA #%00000100 ; Address increment of 32
@setincr:
	STA PPUCTRL
	STA ZP_PPUCTRL
	TXA
	AND #%01000000 ; check the mode flag
	BEQ @copy
	; must be fill then

@fill:
	LDX $04
	LDA ($00),Y
	INY
@fillloop:
	STA PPUDATA
	DEX
	BNE @fillloop
	BEQ @structure ; this structure is done, so move onto the next one

@copy:
	LDX $04
@copyloop:
	LDA ($00),Y
	STA PPUDATA
	INY
	DEX
	BNE @copyloop
	BEQ @structure ; this structure is done, so move onto the next one

@call:
	; ($00) will be overwritten and Y will be cleared, so they need to be preserved
	LDA $01
	PHA ; preserve the high address byte on the stack
	LDA $00
	PHA ; preserve the low address byte on the stack
	INY
	LDA ($00),Y ; get low address byte of substructure
	TAX ; hold onto that low byte
	INY
	LDA ($00),Y ; get high address byte of substructure
	INY
	STX $00 ; write the address of the substructure
	STA $01
	TYA
	PHA ; push the Y index onto the stack
	BNE @buffer

@return:
	PLA ; restore the Y index
	TAY
	PLA ; restore the low address byte
	STA $00
	PLA ; restore the high address byte
	STA $01
	BNE @structure

@done:
	JSR PreventPalettePpuAddr
	RTS
