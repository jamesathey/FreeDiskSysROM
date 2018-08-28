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

; Bits 6 and 7 of IRQ_ACTION determine the behavior of IRQs.
; ($DFFE):         disk game IRQ vector       (if [$0101] = %11xxxxxx)
;  $E1EF :         BIOS acknowledge and delay (if [$0101] = %10xxxxxx)
;  $E1CE :         BIOS disk transfer         (if [$0101] = %01xxxxxx)
;  $E1D9 :         BIOS disk skip bytes       (if [$0101] = %00nnnnnn)
; Set to $80 on reset, aka BIOS acknowledge and delay.
IRQ_ACTION	EQU $0101
IRQ_VEC     EQU $DFFE

IRQ:
    BIT IRQ_ACTION
    BMI @actions2and3
    BVS @diskXfer

; BIOS disk skip bytes - skip n+1 bytes, where n is the lower 6 bits of $101.
; Each IRQ reduces the number of bytes to skip by 1.
    PHA
    LDA IRQ_ACTION
    SEC
    SBC #1 ; another byte skipped, so decrement the bytes remaining to skip
    BCC @byteskipped
    ; once the subtraction underflows, n+1 bytes have been skipped. Set the
    ; IRQ action back to the disk's ISR and clear the byte transfer flag.
    STA IRQ_ACTION
    LDA READDATA ; clear the byte transfer flag in $4030
@byteskipped:
    PLA ; restore A
    RTI

; BIOS disk transfer - assumes that the IRQ was enabled by one of the disk
; routines attempting to transfer data. It doesn't know whether read or write
; is desired, so it does both - it writes to the output register and reads
; from the input register. It also manipulates the stack to behave like a
; subroutine call from the caller of Xfer1stByte or XferByte.
@diskXfer:
    STA WRITEDATA
    PLA ; pop processor status off the stack
    PLA ; discard the ISR return address
    PLA ; so we can return to the caller of Xfer1stByte or XferByte
    LDA READDATA
    RTS

@actions2and3:
    BVS @gameIRQ

; BIOS acknowledge and delay
    PHA
    LDA DISKSTATUS ; clear byte transfer flag
    JSR Delay131
    PLA
    RTI

@gameIRQ:
	JMP (IRQ_VEC) ; game's IRQ vector
