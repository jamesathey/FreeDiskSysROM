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

; Convert pixel screen coordinates to corresponding nametable address (assumes
; no scrolling, and points to first nametable at $2000-$23ff).
; Parameters: $03 = Pixel X cord, $02 = Pixel Y cord
; Returns: $00 = High nametable address, $01 = Low nametable address
; Affects: A
API_ENTRYPOINT $e97d
Pixel2NamConv:
    ; right shift X 3 times to divide by 8 (each NT byte represents an 8x8 area)
    LDA $03
    LSR A
    LSR A
    LSR A
    STA $01

    ; Set the high part of the address to $20 but shifted right twice, so that
    ; it will be shifted left twice later
    LDA #$08
    STA $00

    ; Every 8 pixels of Y represents 32 bytes of NT, so instead of dividing by
    ; 8 and then multiplying by 32, just multiply by 4 and mask the rest
    LDA $02
    ASL A
    ROL $00
    ASL A
    ROL $00
    AND #%11100000
    ; carry is guaranteed to be clear - $00 was 8 before ROL touched it
    ADC $01
    STA $01

	RTS

; Convert a nametable address to corresponding pixel coordinates (assume no
; scrolling).
; Parameters: $00 = High nametable address, $01 = low nametable address
; Returns: $03 = Pixel X cord, $02 = Pixel Y cord
; Affects: A
API_ENTRYPOINT $e997
Nam2PixelConv:
    LDA $01
    ; three left shifts doesn't just multiply by 8, it also shifts out the Y
    ; coordinate portion of the address
    ASL A
    ASL A
    ASL A
    STA $03

    ; the top three bits of the low address are part of the Y coordinate
    LDA $01
    AND #%11100000
    STA $02
    LDA $00
    ; The two lowest bits of the high address are the two high bits of the Y
    ; coordinate. Shift right to get those bits into the carry flag, and
    ; rotate the carry flag into the Y coordinate 
    LSR A
    ROR $02
    LSR A
    ROR $02

	RTS
