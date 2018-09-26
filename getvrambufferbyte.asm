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

; This routine was likely planned to be used in order to avoid useless latency
; on VRAM reads. It compares the VRAM address in ($00) with the address in the
; Yth slot (minimum 1) of the read buffer. If both addresses match, the
; corresponding data byte is returned in A with the carry flag clear. If the
; addresses are different, the address in the Yth slot is overwritten with the
; address in ($00), and the carry flag is set on return.
; Parameters: X = starting index of read buffer, Y = read buffer slot # (minimum 1), $00, $01 = VRAM address to compare with address in read buffer slot
; Returns: carry clear : a previously read byte was returned, carry set : no byte was read, should wait next call to ReadVRAMBuffer
; Affects: A, X, Y
API_ENTRYPOINT $e94f
GetVRAMBufferByte:
    DEX
    DEX
    DEX
    TXA
@loop:
    CLC
    ADC #3
    DEY
    BNE @loop
    TAX 
    LDA $00
    CMP $300,X
    BNE @UpdateAddressHi
    LDA $01
    CMP $301,X
    BNE @UpdateAddressLo
    LDA $302,X
    CLC
	RTS

@UpdateAddressHi:
    STA $300,X
    LDA $01
@UpdateAddressLo:
    STA $301,X
    SEC
    RTS
