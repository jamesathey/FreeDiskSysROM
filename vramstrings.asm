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

; Copy pointed data into the VRAM buffer.
; Parameters: A = High VRAM address, X = Low VRAM address, Y = string length, Direct Pointer = data to be written to VRAM
; Returns: A = $ff : no error, A = $01 : string didn't fit in buffer
; Affects: A, X, Y, $00, $01, $02, $03, $04, $05, $06
API_ENTRYPOINT $e8d2
PrepareVRAMString:
    STA $02
    STX $03
    STY $05
    JSR FetchDirectPtr
    LDY #0
    LDA #1
    BEQ PrepareVRAMStringsGeneric

; Copy a 2D string into the VRAM buffer. The first byte of the data determines
; the width and height of the following string (in tiles):
; Upper nybble = height, lower nybble = width.
; Parameters: A = High VRAM address, X = Low VRAM address, Direct pointer = data to be written to VRAM
; Returns: A = $ff : no error, A = $01 : data didn't fit in buffer
; Affects: A, X, Y, $00, $01, $02, $03, $04, $05, $06
API_ENTRYPOINT $e8e1
PrepareVRAMStrings:
    STA $02
    STX $03
    JSR FetchDirectPtr
    LDY #0
    LDA #$0F ; width
    AND ($00),Y
    STA $05
    LDA ($00),Y ; get the first byte of the data, which indicates the width and height
    INY ; Y is the read index
    LSR ; Shift the upper nibble 4 bits into the lower nibble
    LSR
    LSR
    LSR
    ; for (row = $04; row > 0; row--)
    ; $04 holds # of rows to go
PrepareVRAMStringsGeneric:
    STA $04  ; store the height
    LDX $301 ; X is the write index
@buffer:
    ; write destination address (BIG ENDIAN)
    LDA $02
    STA $302,X
    JSR IncrementWriteIndex
    LDA $03
    STA $302,X
    JSR IncrementWriteIndex
    CLC
    ADC #32; the next string should write to the next row
    STA $03
    BCC @writeLength
    INC $02
@writeLength:
    LDA $05
    STA $302,X
    JSR IncrementWriteIndex
    STA $06
@writeString:
    LDA ($00),Y
    INY
    STA $302,X
    JSR IncrementWriteIndex
    DEC $06
    BNE @writeString ; reached the end of this string?
    DEC $04
    BNE @buffer ; reached the end of the strings?
    LDA #$FF ; no error
    STA $302,X ; write end opcode to write buffer
    STX $301 ; update write buffer end index
	RTS

; Increment the write position in X and check if that would overflow the buffer
IncrementWriteIndex:
    INX
    CPX $300
    BCC @done
    ; uh oh, out of space! Pop the return address pointing to
    ; PrepareVRAMStrings off the stack so that we return to PrepareVRAMStrings'
    ; caller instead.
    PLA
    PLA
    LDX $301   ; since it overflowed, put the "end" opcode back where we started
    LDA #$FF
    STA $302,X ; write end opcode to write buffer
    LDA #1     ; 1 is the error return code
@done:
    RTS
