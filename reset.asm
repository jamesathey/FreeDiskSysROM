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

;[$0102]/[$0103]: PC action on reset
;($DFFC):         disk game reset vector     (if [$0102] = $35, and [$0103] = $53 or $AC)
RESET_ACTION_1 EQU $0102
RESET_ACTION_2 EQU $0103
DISK_RESET_VEC EQU $DFFC


RESET:
    SEI ; disable interrupts
    CLD ; clear decimal mode flag, which doesn't work on the 2A03 anyway

    ; don't allow NMIs until we're ready
    LDY #$00
    STY ZP_PPUCTRL
    STY PPUCTRL

    ; disable rendering, but enable left 8 pixels
    LDA #$06
    STA ZP_PPUMASK
    STA PPUMASK

    ; disable disk I/O and IRQs
    STY IRQCTRL
    STY MASTERIO

    ; the PPU takes a while to warm up. Wait for at least 2 VBlanks before
    ; trying to set the scroll registers
    LDX #2
@waitForVBL:
    LDA PPUSTATUS
    BPL @waitForVBL
    DEX
    BNE @waitForVBL

    ; clear the scroll registers
    LDA #0
    STA ZP_PPUSCROLL1
    STA PPUSCROLL
    STA ZP_PPUSCROLL2
    STA PPUSCROLL

    ; nothing has been written to the joypads or expansion port
    STA ZP_JOYPAD1

    LDA #$2E
    STA ZP_FDSCTRL
    STA FDSCTRL

    LDA #$FF
    STA ZP_EXTCONN

    ; ready, now we can turn on NMIs
    LDA #$80
    STA ZP_PPUCTRL
    STA PPUCTRL
